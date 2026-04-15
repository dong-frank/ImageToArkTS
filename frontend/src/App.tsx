import { useEffect, useLayoutEffect, useRef, useState } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

type ChatMessage = {
  id: string;
  role: string;
  text: string;
  status?: string;
  runId?: string;
};

type UploadedFile = {
  name: string;
  path: string;
  size: number;
  content_type?: string;
  description?: string;
};

type ActivityItem = {
  id: string;
  kind: "tool" | "status" | "error";
  text: string;
  timestamp: number;
  startedAt?: number;
  messageId?: string;
  runId?: string;
  mergeKey?: string;
  toolArgsStream?: string;
  toolLabel?: string;
  toolSummary?: string;
  hasGenericToolChild?: boolean;
};

type WorkspaceNode = {
  name: string;
  path: string;
  type: "directory" | "file";
  size?: number;
  children?: WorkspaceNode[];
};

type FilePreviewKind = "text" | "image" | "binary";

type FilePreviewPayload = {
  ok?: boolean;
  name?: string;
  kind?: FilePreviewKind;
  content_type?: string;
  size?: number;
  text?: string;
  data_url?: string;
  truncated?: boolean;
  message?: string;
  error?: string;
};

type RuntimeStatusMeta = Record<string, string | number | boolean>;

type RuntimeStatusEvent = {
  seq?: number;
  timestamp?: string;
  session_id?: string;
  stage?: string;
  reason?: string;
  forward?: boolean;
  preview?: string;
  meta?: RuntimeStatusMeta;
};

type RuntimeStatusResponse = {
  ok?: boolean;
  session_id?: string;
  since_seq?: number;
  latest_seq?: number;
  count?: number;
  events?: RuntimeStatusEvent[];
};

type SimpleStreamEvent = {
  kind?: string;
  msg_id?: string | null;
  text?: string;
  name?: string;
  args?: unknown;
  payload?: HitlEvent;
};

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "http://127.0.0.1:8080";
const ENABLE_STOP_GENERATION = String(import.meta.env.VITE_ENABLE_STOP_GENERATION ?? "false").toLowerCase() === "true";
const ENABLE_VERBOSE_TRACE = String(import.meta.env.VITE_ENABLE_VERBOSE_TRACE ?? "true").toLowerCase() === "true";


type HitlEvent = {
  hitl_required?: boolean;
  prompt?: string;
  context?: Record<string, unknown>;
};

type SessionItem = {
  id: string;
  title: string;
  createdAt: number;
  updatedAt: number;
};

type SessionSnapshot = {
  messages: ChatMessage[];
  activities: ActivityItem[];
};

const SESSION_LIST_STORAGE_KEY = "imagetoarkts_sessions_v1";
const ACTIVE_SESSION_STORAGE_KEY = "imagetoarkts_active_session_v1";
const SESSION_SNAPSHOT_STORAGE_KEY = "imagetoarkts_session_snapshots_v1";
const PROMPT_EXAMPLES = [
  "例如：上传手绘草图，帮我生成包含手机号登录和验证码功能的页面。",
  "例如：根据需求生成商品列表页，支持搜索筛选，并能下拉刷新。",
  "例如：帮我搭建应用的整体框架，包含首页、详情页和设置页的跳转结构。",
];

const PROMPT_TEMPLATES = [
    "生成一个鸿蒙版计算器App，包含标准与科学计算模式，界面简洁现代。",
];

function createDefaultSession(index = 1): SessionItem {
  const now = Date.now();
  return {
    id: crypto.randomUUID(),
    title: `新会话 ${index}`,
    createdAt: now,
    updatedAt: now,
  };
}

function readSessionList(): SessionItem[] {
  try {
    const raw = localStorage.getItem(SESSION_LIST_STORAGE_KEY);
    if (!raw) {
      return [];
    }
    const parsed = JSON.parse(raw) as SessionItem[];
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed
      .filter((item) => item && typeof item.id === "string" && item.id.trim().length > 0)
      .map((item, idx) => {
        const now = Date.now();
        return {
          id: item.id,
          title: typeof item.title === "string" && item.title.trim() ? item.title.trim() : `会话 ${idx + 1}`,
          createdAt: Number.isFinite(item.createdAt) ? item.createdAt : now,
          updatedAt: Number.isFinite(item.updatedAt) ? item.updatedAt : now,
        };
      });
  } catch {
    return [];
  }
}

function persistSessionList(items: SessionItem[]): void {
  localStorage.setItem(SESSION_LIST_STORAGE_KEY, JSON.stringify(items));
}

function readActiveSessionId(candidates: SessionItem[]): string {
  const saved = localStorage.getItem(ACTIVE_SESSION_STORAGE_KEY);
  if (saved && candidates.some((item) => item.id === saved)) {
    return saved;
  }
  return candidates[0]?.id ?? createDefaultSession().id;
}

function persistActiveSessionId(sessionId: string): void {
  localStorage.setItem(ACTIVE_SESSION_STORAGE_KEY, sessionId);
}

function readSessionSnapshots(): Record<string, SessionSnapshot> {
  try {
    const raw = localStorage.getItem(SESSION_SNAPSHOT_STORAGE_KEY);
    if (!raw) {
      return {};
    }
    const parsed = JSON.parse(raw) as Record<string, SessionSnapshot>;
    if (!parsed || typeof parsed !== "object") {
      return {};
    }
    return parsed;
  } catch {
    return {};
  }
}

function readSnapshotForSession(sessionId: string): SessionSnapshot | null {
  const snapshots = readSessionSnapshots();
  const snapshot = snapshots[sessionId];
  if (!snapshot) {
    return null;
  }
  return {
    messages: Array.isArray(snapshot.messages) ? snapshot.messages : [],
    activities: Array.isArray(snapshot.activities) ? snapshot.activities : [],
  };
}

function persistSnapshotForSession(sessionId: string, snapshot: SessionSnapshot): void {
  const snapshots = readSessionSnapshots();
  snapshots[sessionId] = snapshot;
  localStorage.setItem(SESSION_SNAPSHOT_STORAGE_KEY, JSON.stringify(snapshots));
}

function deleteSnapshotForSession(sessionId: string): void {
  const snapshots = readSessionSnapshots();
  if (!Object.prototype.hasOwnProperty.call(snapshots, sessionId)) {
    return;
  }
  delete snapshots[sessionId];
  localStorage.setItem(SESSION_SNAPSHOT_STORAGE_KEY, JSON.stringify(snapshots));
}

function formatBytes(size: number): string {
  if (size < 1024) {
    return `${size} B`;
  }
  if (size < 1024 * 1024) {
    return `${(size / 1024).toFixed(1)} KB`;
  }
  return `${(size / (1024 * 1024)).toFixed(1)} MB`;
}

function createRuntimeMessage(text: string): ChatMessage {
  return {
    id: `local-${crypto.randomUUID()}`,
    role: "assistant",
    text,
    status: "completed",
  };
}

function hasImageFile(files: FileList | null): boolean {
  if (!files || files.length === 0) {
    return false;
  }

  return Array.from(files).some((file) => {
    if (file.type.startsWith("image/")) {
      return true;
    }
    return /\.(png|jpe?g|gif|webp|bmp|svg|heic)$/i.test(file.name);
  });
}

function hasRenderableMessageText(message: ChatMessage): boolean {
  if (message.role === "user") {
    return true;
  }
  return message.text.trim().length > 0;
}

function normalizeMessageStatus(status: string | undefined): string {
  const normalized = (status ?? "in_progress").toLowerCase();
  if (normalized === "running") {
    return "in_progress";
  }
  return normalized;
}

function getMessageStatusLabel(status: string | undefined): string {
  const normalized = normalizeMessageStatus(status);
  switch (normalized) {
    case "completed":
      return "已完成";
    case "failed":
      return "失败";
    case "cancelled":
      return "已取消";
    case "requires_action":
      return "需处理";
    case "requires_human_input":
      return "需人工输入";
    case "incomplete":
      return "未完成";
    default:
      return "进行中";
  }
}

function mergeStreamingText(existingText: string, incomingText: string): string {
  if (!incomingText) {
    return existingText;
  }
  if (!existingText) {
    return incomingText;
  }

  // Some backends send full snapshots, others send deltas. Handle both safely.
  if (incomingText.startsWith(existingText)) {
    return incomingText;
  }
  if (existingText.startsWith(incomingText) || existingText.endsWith(incomingText)) {
    return existingText;
  }
  if (incomingText.includes(existingText)) {
    return incomingText;
  }

  return `${existingText}${incomingText}`;
}

function isTrivialToolSeed(value: string): boolean {
  const trimmed = value.trim();
  return trimmed === "" || trimmed === "{}" || trimmed === '""' || trimmed === "null";
}

function mergeStatusTraceText(existingText: string, incomingText: string): string {
  const incoming = incomingText.trim();
  if (!incoming) {
    return existingText;
  }
  if (!existingText) {
    return incoming;
  }
  if (incoming.startsWith(existingText)) {
    return incoming;
  }
  if (existingText.includes(incoming) || existingText.endsWith(incoming)) {
    return existingText;
  }
  return `${existingText}\n${incoming}`;
}

function formatDurationMs(ms: number): string {
  const safe = Math.max(0, ms);
  if (safe < 1000) {
    return `${safe}ms`;
  }
  if (safe < 60000) {
    return `${(safe / 1000).toFixed(1)}s`;
  }
  const minutes = Math.floor(safe / 60000);
  const seconds = Math.floor((safe % 60000) / 1000);
  return `${minutes}m ${seconds}s`;
}

function renderMessageBody(message: ChatMessage) {

  if (message.role === "assistant") {
    if (!message.text || message.text.trim() === "") {
      return null;
    }
    return (
      <div className="message-text markdown-body">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{message.text}</ReactMarkdown>
      </div>
    );
  }

  return <div className="message-text">{message.text}</div>;
}

function getToolLabel(event: SimpleStreamEvent): string {
  const toolName = typeof event.name === "string" ? event.name.trim() : "";
  return toolName || "tool";
}

function clipText(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }
  return `${value.slice(0, maxLength)}...`;
}

function summarizeTodoList(items: Array<Record<string, unknown>>, verbose: boolean): string {
  const total = items.length;
  const completed = items.filter((item) => {
    const status = typeof item.status === "string" ? item.status.toLowerCase() : "";
    return status === "completed" || status === "done";
  }).length;
  const inProgress = items.filter(
    (item) => typeof item.status === "string" && item.status.toLowerCase() === "in_progress"
  ).length;
  const pending = items.filter(
    (item) => typeof item.status === "string" && item.status.toLowerCase() === "pending"
  ).length;

  const visibleCount = verbose ? 6 : 3;
  const labels = items
    .slice(0, visibleCount)
    .map((item, index) => {
      const content = typeof item.content === "string" ? item.content.trim() : `task-${index + 1}`;
      const status = typeof item.status === "string" ? item.status : "unknown";
      return `${index + 1}.${clipText(content, 26)}[${status}]`;
    })
    .join("; ");

  return `todos ${completed}/${total} done (in_progress=${inProgress}, pending=${pending})${labels ? ` | ${labels}` : ""}`;
}

function tryParseStructuredArgsText(input: string): unknown {
  const trimmed = input.trim();
  if (!trimmed) {
    return null;
  }

  const candidates: string[] = [trimmed];

  let withoutEmptyObjects = trimmed;
  while (withoutEmptyObjects.startsWith("{}")) {
    withoutEmptyObjects = withoutEmptyObjects.slice(2).trimStart();
  }
  if (withoutEmptyObjects && withoutEmptyObjects !== trimmed) {
    candidates.push(withoutEmptyObjects);
  }

  const todosStart = withoutEmptyObjects.indexOf('{"todos"');
  if (todosStart >= 0) {
    const todosSlice = withoutEmptyObjects.slice(todosStart).trim();
    candidates.push(todosSlice);
    if (!todosSlice.endsWith("}")) {
      candidates.push(`${todosSlice}}`);
    }
  }

  for (const candidate of candidates) {
    try {
      const parsed = JSON.parse(candidate);
      return parsed;
    } catch {
      // try next candidate
    }
  }

  return trimmed;
}

function summarizeLoosePayloadText(text: string): string {
  const todoMatches = [...text.matchAll(/"content"\s*:\s*"([^"]+)"\s*,\s*"status"\s*:\s*"([^"]+)"/g)];
  if (todoMatches.length > 0) {
    const todoItems = todoMatches.map((match) => ({
      content: match[1],
      status: match[2],
    }));
    return summarizeTodoList(todoItems, false);
  }

  const descMatch = text.match(/"description"\s*:\s*"([^"]+)/);
  const agentMatch = text.match(/"subagent_type"\s*:\s*"([^"]+)/);
  if (descMatch || agentMatch) {
    const desc = descMatch ? clipText(descMatch[1].trim(), 72) : "";
    const agent = agentMatch ? agentMatch[1].trim() : "";
    if (agent && desc) {
      return `task(${agent}): ${desc}`;
    }
    if (agent) {
      return `task(${agent})`;
    }
    if (desc) {
      return `task: ${desc}`;
    }
  }

  return text.length > 80 ? `payload_len=${text.length}` : text;
}

function extractToolSummaryFromText(text: string): string {
  const source = text.trim();
  const pipeArgsMarker = "| args: ";
  const pipeArgsIndex = source.indexOf(pipeArgsMarker);
  if (pipeArgsIndex >= 0) {
    return source.slice(pipeArgsIndex + pipeArgsMarker.length).trim();
  }

  const argsMarker = " args: ";
  const argsIndex = source.indexOf(argsMarker);
  if (argsIndex >= 0) {
    return source.slice(argsIndex + argsMarker.length).trim();
  }

  const colonMatch = source.match(/^[A-Za-z0-9_\-]+:\s*(.*)$/);
  if (colonMatch && colonMatch[1]) {
    return colonMatch[1].trim();
  }

  return source.replace(/^tool=[^\s]+\s*/i, "").trim();
}

function normalizeToolArgsText(raw: string): string {
  if (!raw) {
    return "";
  }

  const unescaped = raw
    .replace(/\\n/g, "\n")
    .replace(/\n/g, "\n")
    .replace(/\\t/g, " ")
    .replace(/\\\"/g, '"')
    .replace(/\\\//g, "/")
    .replace(/\\\\/g, "\\");

  const stripped = unescaped.replace(/[{}\[\]"]/g, " ");
  return stripped
    .replace(/\r/g, "")
    .split("\n")
    .map((line) => line.replace(/\s+/g, " ").trim())
    .filter((line, index, arr) => !(line === "" && arr[index - 1] === ""))
    .join("\n")
    .trim();
}

function toTodoMarkdown(items: Array<Record<string, unknown>>): string {
  if (items.length === 0) {
    return "";
  }

  return items
    .map((item) => {
      const content = typeof item.content === "string" ? item.content.trim() : "(未命名任务)";
      const status = typeof item.status === "string" ? item.status.toLowerCase() : "unknown";
      const checked = status === "completed" || status === "done";
      return `- [${checked ? "x" : " "}] ${content}`;
    })
    .join("\n");
}

function toMarkdownFromToolPayload(payload: unknown): string {
  if (!payload) {
    return "";
  }

  if (typeof payload === "string") {
    return normalizeToolArgsText(payload);
  }

  if (Array.isArray(payload)) {
    const todoLike = payload.every(
      (item) => item && typeof item === "object" && "content" in (item as Record<string, unknown>)
    );
    if (todoLike) {
      return toTodoMarkdown(payload as Array<Record<string, unknown>>);
    }
    return "";
  }

  if (typeof payload === "object") {
    const record = payload as Record<string, unknown>;
    const filePath = typeof record.file_path === "string" ? record.file_path.trim() : "";
    const content = typeof record.content === "string" ? record.content.trim() : "";
    if (filePath || content) {
      const pathLine = filePath ? `**文件**: ${filePath}` : "";
      const contentBlock = content ? `\n\n\`\`\`text\n${content}\n\`\`\`` : "";
      return `${pathLine}${contentBlock}`.trim();
    }

    const description = typeof record.description === "string" ? record.description.trim() : "";
    if (description) {
      return description;
    }

    const todos = record.todos;
    if (Array.isArray(todos)) {
      return toTodoMarkdown(todos as Array<Record<string, unknown>>);
    }
  }

  return "";
}

function buildToolDetailMarkdown(toolArgsStream: string | undefined, fallbackSummary: string): string {
  const raw = (toolArgsStream ?? "").trim();
  if (!raw) {
    return fallbackSummary;
  }

  const parsed = tryParseStructuredArgsText(raw);
  const markdownPayload = toMarkdownFromToolPayload(parsed);
  if (markdownPayload) {
    return markdownPayload;
  }

  if (typeof parsed === "string") {
    const compact = normalizeToolArgsText(parsed);
    if (compact) {
      return compact;
    }
  }

  const fallback = normalizeToolArgsText(raw);
  return fallback || fallbackSummary;
}

function getActivityToolLabel(item: ActivityItem): string {
  const explicit = (item.toolLabel ?? "").trim();
  if (explicit) {
    return explicit;
  }

  const source = (item.text ?? "").trim();
  if (!source) {
    return "tool";
  }

  const argsMatch = source.match(/^([A-Za-z0-9_\-:]+)\s+args:/);
  if (argsMatch && argsMatch[1]) {
    return argsMatch[1];
  }

  const colonMatch = source.match(/^([A-Za-z0-9_\-:]+):/);
  if (colonMatch && colonMatch[1]) {
    return colonMatch[1];
  }

  return "tool";
}

function summarizeToolArgs(rawArgs: unknown, verbose: boolean): string {
  let normalized: unknown = rawArgs;
  if (typeof rawArgs === "string") {
    const trimmed = rawArgs.trim();
    if (!trimmed) {
      return "";
    }
    normalized = tryParseStructuredArgsText(trimmed);
  }

  if (Array.isArray(normalized)) {
    const looksLikeStepList = normalized.every(
      (item) => item && typeof item === "object" && "status" in (item as Record<string, unknown>)
    );
    if (looksLikeStepList) {
      const statusCounts: Record<string, number> = {};
      let currentStep = "";
      for (const item of normalized as Array<Record<string, unknown>>) {
        const status = typeof item.status === "string" ? item.status : "unknown";
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        if (!currentStep && status === "in_progress" && typeof item.content === "string") {
          currentStep = item.content.trim();
        }
      }
      const currentPreview = currentStep
        ? ` current=${currentStep.slice(0, 48)}${currentStep.length > 48 ? "..." : ""}`
        : "";
      return `steps=${normalized.length} in_progress=${statusCounts.in_progress ?? 0} pending=${statusCounts.pending ?? 0} completed=${statusCounts.completed ?? 0}${currentPreview}`;
    }
  }

  if (normalized && typeof normalized === "object" && !Array.isArray(normalized)) {
    const normalizedRecord = normalized as Record<string, unknown>;
    const maybeTodos = normalizedRecord.todos;
    if (Array.isArray(maybeTodos)) {
      return summarizeTodoList(maybeTodos as Array<Record<string, unknown>>, verbose);
    }

    const description =
      typeof normalizedRecord.description === "string" ? normalizedRecord.description.trim() : "";
    const subagent =
      typeof normalizedRecord.subagent_type === "string" ? normalizedRecord.subagent_type.trim() : "";
    if (description || subagent) {
      const shortDesc = description ? clipText(description, verbose ? 180 : 72) : "";
      if (subagent && shortDesc) {
        return `task(${subagent}): ${shortDesc}`;
      }
      if (subagent) {
        return `task(${subagent})`;
      }
      return `task: ${shortDesc}`;
    }
  }

  if (typeof normalized === "string") {
    return summarizeLoosePayloadText(normalized);
  }

  try {
    const serialized = JSON.stringify(normalized);
    if (!serialized || serialized === "null") {
      return "";
    }
    const limit = verbose ? 2000 : 260;
    return serialized.length > limit ? `${serialized.slice(0, limit)}...` : serialized;
  } catch {
    return String(normalized ?? "");
  }
}

function formatToolActivityText(event: SimpleStreamEvent, verbose: boolean, forcedToolLabel?: string): string {
  const explicitText = typeof event.text === "string" ? event.text.trim() : "";
  const toolName = forcedToolLabel || getToolLabel(event);

  const argsText = event.args !== undefined ? summarizeToolArgs(event.args, verbose) : "";

  if (explicitText) {
    return argsText ? `${toolName}: ${explicitText} | args: ${argsText}` : `${toolName}: ${explicitText}`;
  }
  return argsText ? `${toolName} args: ${argsText}` : toolName;
}

function buildToolArgsStream(previous: string | undefined, incomingArgs: unknown): string | undefined {
  const prevRaw = previous ?? "";
  const prev = isTrivialToolSeed(prevRaw) ? "" : prevRaw;

  if (typeof incomingArgs === "string") {
    const incomingRaw = incomingArgs;
    const incoming = isTrivialToolSeed(incomingRaw) ? "" : incomingRaw;

    if (!incoming) {
      return prev || undefined;
    }
    if (!prev) {
      return incoming;
    }
    return mergeStreamingText(prev, incoming);
  }

  if (incomingArgs === undefined) {
    return prev || undefined;
  }

  try {
    const serialized = JSON.stringify(incomingArgs);
    if (!serialized || serialized === "null") {
      return prev || undefined;
    }
    return serialized;
  } catch {
    return prev || undefined;
  }
}

function extractPreviewText(raw: string | undefined): string {
  const text = (raw ?? "").trim();
  if (!text) {
    return "";
  }

  const previewKey = "preview=";
  const previewIndex = text.toLowerCase().indexOf(previewKey);
  if (previewIndex >= 0) {
    const afterPreview = text.slice(previewIndex + previewKey.length).trim();
    return afterPreview;
  }

  return text;
}

function isExecutionStatusText(raw: string): boolean {
  const normalized = raw.toLowerCase();

  if (
    normalized.includes("assistant_text") ||
    normalized.includes("yield_text") ||
    normalized.includes("forward_all")
  ) {
    return false;
  }

  return (
    normalized.includes("tool") ||
    normalized.includes("task") ||
    normalized.includes("action") ||
    normalized.includes("interrupt") ||
    normalized.includes("requires_action") ||
    normalized.includes("forward_structured_tool")
  );
}

function isExecutionRuntimeEvent(event: RuntimeStatusEvent): boolean {
  const reason = (event.reason ?? "").toLowerCase();
  if (reason.includes("forward_structured_tool") || reason.includes("tool")) {
    return true;
  }

  if (reason.includes("forward_all") || reason.includes("assistant_text") || reason.includes("empty_content")) {
    return false;
  }

  const meta = event.meta && typeof event.meta === "object" ? event.meta : undefined;
  const metaBlob = [
    typeof meta?.event === "string" ? meta.event : "",
    typeof meta?.type === "string" ? meta.type : "",
    typeof meta?.name === "string" ? meta.name : "",
    typeof meta?.langgraph_node === "string" ? meta.langgraph_node : "",
  ]
    .join(" ")
    .toLowerCase();

  return /tool|task|action|interrupt/.test(metaBlob);
}

function buildRuntimeStatusText(event: RuntimeStatusEvent): string {
  const preview = extractPreviewText(typeof event.preview === "string" ? event.preview : "");
  return preview ? `preview: ${preview}` : "";
}

export default function App() {
  const [bootState] = useState(() => {
    const stored = readSessionList();
    return {
      sessions: stored,
      activeSessionId: "",
    };
  });
  const [simulatorCollapsed, setSimulatorCollapsed] = useState(true);
  const [centerView, setCenterView] = useState<"conversation" | "file-preview">("conversation");
  const [activePreviewFile, setActivePreviewFile] = useState<UploadedFile | null>(null);
  const [activeWorkspacePreviewPath, setActiveWorkspacePreviewPath] = useState<string | null>(null);
  const [filePreview, setFilePreview] = useState<FilePreviewPayload | null>(null);
  const [isPreviewLoading, setIsPreviewLoading] = useState(false);
  const [filePreviewError, setFilePreviewError] = useState<string | null>(null);
  const [sessions, setSessions] = useState<SessionItem[]>(bootState.sessions);
  const [sessionId, setSessionId] = useState(bootState.activeSessionId);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [workspaceTree, setWorkspaceTree] = useState<WorkspaceNode | null>(null);
  const [input, setInput] = useState("");
  const [selectedFiles, setSelectedFiles] = useState<FileList | null>(null);
  const [pendingImageFile, setPendingImageFile] = useState<File | null>(null);
  const [pendingImagePreviewUrl, setPendingImagePreviewUrl] = useState("");
  const [imageDescription, setImageDescription] = useState("");
  const [showImageDescriptionDialog, setShowImageDescriptionDialog] = useState(false);
  const [deletingFileName, setDeletingFileName] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [isResetting, setIsResetting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hitlPrompt, setHitlPrompt] = useState("");
  const [hitlContextText, setHitlContextText] = useState("");
  const [hitlInput, setHitlInput] = useState("");
  const [hitlPending, setHitlPending] = useState(false);
  const [pendingDeleteSession, setPendingDeleteSession] = useState<SessionItem | null>(null);
  const [openSessionMenuId, setOpenSessionMenuId] = useState<string | null>(null);
  const [promptExampleIndex, setPromptExampleIndex] = useState(0);
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const pendingAssistantMessageIdRef = useRef<string | null>(null);
  const messageSegmentByStreamIdRef = useRef<Record<string, number>>({});
  const lastToolByStreamIdRef = useRef<Record<string, string>>({});
  const runtimeStatusCursorRef = useRef<Record<string, number>>({});
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const isRestoringSessionRef = useRef(false);
  const shouldScrollToLatestRef = useRef(false);
  const streamAbortControllerRef = useRef<AbortController | null>(null);
  const latestSessionIdRef = useRef(sessionId);
  const [isStopping, setIsStopping] = useState(false);

  useEffect(() => {
    latestSessionIdRef.current = sessionId;
  }, [sessionId]);

  useEffect(() => {
    if (!sessionId) {
      return;
    }
    const exists = sessions.some((item) => item.id === sessionId);
    if (!exists && sessions.length > 0) {
      setSessionId(sessions[0].id);
    }
  }, [sessions, sessionId]);

  useEffect(() => {
    persistSessionList(sessions);
  }, [sessions]);

  useEffect(() => {
    if (!sessionId) {
      return;
    }
    persistActiveSessionId(sessionId);
  }, [sessionId]);

  useEffect(() => {
    if (!sessionId) {
      isRestoringSessionRef.current = false;
      messageSegmentByStreamIdRef.current = {};
      lastToolByStreamIdRef.current = {};
      setMessages([]);
      setActivities([]);
      setFiles([]);
      setWorkspaceTree(null);
      setCenterView("conversation");
      setActivePreviewFile(null);
      setActiveWorkspacePreviewPath(null);
      setFilePreview(null);
      setFilePreviewError(null);
      setHitlPending(false);
      setHitlPrompt("");
      setHitlContextText("");
      setHitlInput("");
      return;
    }

    isRestoringSessionRef.current = true;
  messageSegmentByStreamIdRef.current = {};
  lastToolByStreamIdRef.current = {};
    const snapshot = readSnapshotForSession(sessionId);
    setMessages(snapshot?.messages ?? []);
    setActivities(snapshot?.activities ?? []);
    setCenterView("conversation");
    setActivePreviewFile(null);
    setActiveWorkspacePreviewPath(null);
    setFilePreview(null);
    setFilePreviewError(null);
    setInput("");
    setError(null);
    setHitlPending(false);
    setHitlPrompt("");
    setHitlContextText("");
    setHitlInput("");
    void refreshFiles();
    void refreshWorkspaceTree();
  }, [sessionId]);

  useEffect(() => {
    if (!sessionId) {
      return;
    }
    if (isRestoringSessionRef.current) {
      isRestoringSessionRef.current = false;
      return;
    }

    persistSnapshotForSession(sessionId, { messages, activities });
    setSessions((current) =>
      current.map((item) =>
        item.id === sessionId ? { ...item, updatedAt: Date.now() } : item
      )
    );
  }, [activities, messages, sessionId]);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "auto",
    });
  }, [messages, activities]);

  useLayoutEffect(() => {
    if (!shouldScrollToLatestRef.current || centerView !== "conversation") {
      return;
    }

    const container = scrollRef.current;
    if (!container) {
      return;
    }

    container.scrollTo({
      top: container.scrollHeight,
      behavior: "auto",
    });
    const frame = window.requestAnimationFrame(() => {
      container.scrollTo({
        top: container.scrollHeight,
        behavior: "auto",
      });
      shouldScrollToLatestRef.current = false;
    });

    return () => window.cancelAnimationFrame(frame);
  }, [centerView, messages.length, activities.length]);

  useEffect(() => {
    if (!sessionId || !isSending) {
      return;
    }

    let disposed = false;
    const controller = new AbortController();

    const pollRuntimeStatus = async () => {
      if (disposed) {
        return;
      }

      const sinceSeq = runtimeStatusCursorRef.current[sessionId] ?? 0;
      try {
        const response = await fetch(
          `${API_BASE}/runtime/status?session_id=${encodeURIComponent(sessionId)}&since_seq=${sinceSeq}&limit=120`,
          {
            signal: controller.signal,
          }
        );
        if (!response.ok) {
          return;
        }

        const data = (await response.json()) as RuntimeStatusResponse;
        if (!data.ok) {
          return;
        }

        const latestSeq = Number.isFinite(data.latest_seq) ? Number(data.latest_seq) : sinceSeq;
        runtimeStatusCursorRef.current[sessionId] = Math.max(sinceSeq, latestSeq);

        const events = Array.isArray(data.events) ? data.events : [];
        if (events.length === 0) {
          return;
        }

        setActivities((current) => {
          const mergeKey = `status-preview::session:${sessionId}`;
          const existingIndex = current.findIndex(
            (item) => item.kind === "status" && item.mergeKey === mergeKey
          );
          let mergedText = existingIndex >= 0 ? current[existingIndex].text : "";
          let latestTimestamp = Date.now();

          for (const event of events) {
            if (!isExecutionRuntimeEvent(event)) {
              continue;
            }

            const statusText = buildRuntimeStatusText(event);
            if (!statusText) {
              continue;
            }
            const timestamp = event.timestamp ? Date.parse(event.timestamp) : Date.now();
            latestTimestamp = Number.isFinite(timestamp) ? timestamp : Date.now();
            mergedText = mergeStatusTraceText(mergedText, statusText);
          }

          if (!mergedText) {
            return current;
          }

          if (existingIndex < 0) {
            return [
              ...current,
              {
                id: crypto.randomUUID(),
                kind: "status",
                text: mergedText,
                timestamp: latestTimestamp,
                mergeKey,
              },
            ];
          }

          return current.map((item, index) =>
            index === existingIndex
              ? {
                  ...item,
                  text: mergedText,
                  timestamp: latestTimestamp,
                }
              : item
          );
        });
      } catch {
        // Ignore polling errors while the main stream is active.
      }
    };

    void pollRuntimeStatus();
    const timer = window.setInterval(() => {
      void pollRuntimeStatus();
    }, 900);

    return () => {
      disposed = true;
      controller.abort();
      window.clearInterval(timer);
    };
  }, [isSending, sessionId]);

  useEffect(() => {
    if (!sessionId) {
      setWorkspaceTree(null);
      return;
    }

    if (!isSending) {
      void refreshWorkspaceTree().catch(() => {
        // Ignore refresh errors when stream just finished.
      });
      return;
    }

    let disposed = false;

    const pollWorkspaceTree = async () => {
      if (disposed) {
        return;
      }
      try {
        await refreshWorkspaceTree();
      } catch {
        // Ignore polling errors while generation is running.
      }
    };

    void pollWorkspaceTree();
    const timer = window.setInterval(() => {
      void pollWorkspaceTree();
    }, 1500);

    return () => {
      disposed = true;
      window.clearInterval(timer);
    };
  }, [isSending, sessionId]);

  useEffect(() => {
    return () => {
      if (pendingImagePreviewUrl) {
        URL.revokeObjectURL(pendingImagePreviewUrl);
      }
    };
  }, [pendingImagePreviewUrl]);

  useEffect(() => {
    const handleDocumentPointerDown = () => {
      setOpenSessionMenuId(null);
    };

    document.addEventListener("pointerdown", handleDocumentPointerDown);
    return () => {
      document.removeEventListener("pointerdown", handleDocumentPointerDown);
    };
  }, []);

  useEffect(() => {
    if (input.trim() || files.length > 0) {
      return;
    }

    const timer = window.setInterval(() => {
      setPromptExampleIndex((current) => (current + 1) % PROMPT_EXAMPLES.length);
    }, 4500);

    return () => window.clearInterval(timer);
  }, [files.length, input]);

  function clearFileInputValue() {
    const fileInput = fileInputRef.current;
    if (fileInput) {
      fileInput.value = "";
    }
  }

  function handleCreateSession() {
    setOpenSessionMenuId(null);
    shouldScrollToLatestRef.current = true;
    setFiles([]);
    setWorkspaceTree(null);
    const freshSession = createDefaultSession(sessions.length + 1);
    latestSessionIdRef.current = freshSession.id;
    setSessions((current) => [freshSession, ...current]);
    setSessionId(freshSession.id);
    void refreshFilesFor(freshSession.id).catch(() => {
      // Best-effort bootstrap to ensure backend session dirs are created.
    });
    void refreshWorkspaceTreeFor(freshSession.id).catch(() => {
      // Best-effort bootstrap to ensure backend session dirs are created.
    });
    setCenterView("conversation");
    setActivePreviewFile(null);
    setActiveWorkspacePreviewPath(null);
    setFilePreview(null);
    setFilePreviewError(null);
  }

  function handleSwitchSession(nextSessionId: string) {
    setOpenSessionMenuId(null);
    if (!nextSessionId) {
      return;
    }
    if (nextSessionId === sessionId) {
      if (centerView !== "conversation") {
        shouldScrollToLatestRef.current = true;
        setCenterView("conversation");
        setActivePreviewFile(null);
        setActiveWorkspacePreviewPath(null);
        setFilePreview(null);
        setFilePreviewError(null);
      }
      return;
    }
    shouldScrollToLatestRef.current = true;
    setSessionId(nextSessionId);
    setCenterView("conversation");
    setActivePreviewFile(null);
    setActiveWorkspacePreviewPath(null);
    setFilePreview(null);
    setFilePreviewError(null);
  }

  function handleDeleteSession(targetSessionId: string) {
    setOpenSessionMenuId(null);
    if (!targetSessionId) {
      return;
    }

    setSessions((current) => {
      if (current.length <= 1 && current[0]?.id === targetSessionId) {
        const fallback = createDefaultSession(1);
        setSessionId(fallback.id);
        persistActiveSessionId(fallback.id);
        deleteSnapshotForSession(targetSessionId);
        setFiles([]);
        setWorkspaceTree(null);
        return [fallback];
      }

      const next = current.filter((item) => item.id !== targetSessionId);
      if (next.length === current.length) {
        return current;
      }

      deleteSnapshotForSession(targetSessionId);

      if (sessionId === targetSessionId) {
        const fallbackSession = next[0] ?? createDefaultSession(1);
        setSessionId(fallbackSession.id);
        persistActiveSessionId(fallbackSession.id);
        setFiles([]);
        setWorkspaceTree(null);
      }

      return next.length > 0 ? next : [createDefaultSession(1)];
    });

    if (sessionId === targetSessionId) {
      setCenterView("conversation");
      setActivePreviewFile(null);
      setActiveWorkspacePreviewPath(null);
      setFilePreview(null);
      setFilePreviewError(null);
      setFiles([]);
      setWorkspaceTree(null);
    }
  }

  function requestDeleteSession(targetSessionId: string) {
    setOpenSessionMenuId(null);
    const target = sessions.find((item) => item.id === targetSessionId) ?? null;
    setPendingDeleteSession(target);
  }

  function requestRenameSession(targetSessionId: string) {
    setOpenSessionMenuId(null);
    const target = sessions.find((item) => item.id === targetSessionId) ?? null;
    if (!target) {
      return;
    }

    const renamed = window.prompt("请输入新的会话名称", target.title);
    if (renamed === null) {
      return;
    }

    const nextTitle = renamed.trim();
    if (!nextTitle) {
      return;
    }

    setSessions((current) =>
      current.map((item) =>
        item.id === targetSessionId
          ? { ...item, title: nextTitle.slice(0, 64), updatedAt: Date.now() }
          : item
      )
    );
  }

  function confirmDeleteSession() {
    if (!pendingDeleteSession) {
      return;
    }
    handleDeleteSession(pendingDeleteSession.id);
    setPendingDeleteSession(null);
  }

  function cancelDeleteSession() {
    setPendingDeleteSession(null);
  }

  async function handlePreviewFile(file: UploadedFile) {
    setCenterView("file-preview");
    setActivePreviewFile(file);
    setActiveWorkspacePreviewPath(null);
    setIsPreviewLoading(true);
    setFilePreview(null);
    setFilePreviewError(null);

    try {
      const response = await fetch(
        `${API_BASE}/user-input/files/${encodeURIComponent(file.name)}/preview?session_id=${encodeURIComponent(sessionId)}`
      );
      const data = (await response.json()) as FilePreviewPayload;
      if (!response.ok || !data.ok) {
        throw new Error(data.error || `Preview failed: ${response.status}`);
      }
      setFilePreview(data);
    } catch (previewError) {
      const message = previewError instanceof Error ? previewError.message : "预览失败";
      setFilePreviewError(message);
    } finally {
      setIsPreviewLoading(false);
    }
  }

  async function handlePreviewWorkspaceFile(node: WorkspaceNode) {
    if (node.type !== "file") {
      return;
    }
    setCenterView("file-preview");
    setActivePreviewFile(null);
    setActiveWorkspacePreviewPath(node.path);
    setIsPreviewLoading(true);
    setFilePreview(null);
    setFilePreviewError(null);

    try {
      const response = await fetch(
        `${API_BASE}/workspace/files/preview?session_id=${encodeURIComponent(sessionId)}&workspace_path=${encodeURIComponent(node.path)}`
      );
      const data = (await response.json()) as FilePreviewPayload;
      if (!response.ok || !data.ok) {
        throw new Error(data.error || `Preview failed: ${response.status}`);
      }
      setFilePreview(data);
    } catch (previewError) {
      const message = previewError instanceof Error ? previewError.message : "预览失败";
      setFilePreviewError(message);
    } finally {
      setIsPreviewLoading(false);
    }
  }

  function maybeRenameSessionFromUserInput(text: string, targetSessionId = sessionId) {
    const cleaned = text.trim();
    if (!cleaned) {
      return;
    }
    const title = cleaned.length > 24 ? `${cleaned.slice(0, 24)}...` : cleaned;
    setSessions((current) =>
      current.map((item) => {
        if (item.id !== targetSessionId) {
          return item;
        }
        if (!item.title.startsWith("新会话")) {
          return { ...item, updatedAt: Date.now() };
        }
        return { ...item, title, updatedAt: Date.now() };
      })
    );
  }

  function ensureSessionForWork(): string {
    const currentSessionId = latestSessionIdRef.current || sessionId;
    if (currentSessionId) {
      return currentSessionId;
    }

    const freshSession = createDefaultSession(sessions.length + 1);
    latestSessionIdRef.current = freshSession.id;
    runtimeStatusCursorRef.current[freshSession.id] = 0;
    persistSnapshotForSession(freshSession.id, {
      messages: [],
      activities: [],
    });
    setSessions((current) => [freshSession, ...current]);
    setSessionId(freshSession.id);
    setCenterView("conversation");
    return freshSession.id;
  }

  async function uploadFiles(filesToUpload: File[], targetSessionId: string, description = "") {
    const formData = new FormData();
    for (const file of filesToUpload) {
      formData.append("files", file);
    }
    formData.append("session_id", targetSessionId);
    if (description.trim()) {
      formData.append("image_description", description.trim());
    }

    const response = await fetch(`${API_BASE}/user-input/upload`, {
      method: "POST",
      body: formData,
    });
    if (!response.ok) {
      throw new Error(`Upload failed: ${response.status}`);
    }
  }

  async function refreshFilesFor(targetSessionId: string) {
    if (!targetSessionId) {
      setFiles([]);
      return;
    }
    const response = await fetch(
      `${API_BASE}/user-input/files?session_id=${encodeURIComponent(targetSessionId)}`
    );
    if (!response.ok) {
      throw new Error(`Failed to list files: ${response.status}`);
    }
    const data = (await response.json()) as { files: UploadedFile[] };
    if (latestSessionIdRef.current === targetSessionId) {
      setFiles(data.files ?? []);
    }
  }

  async function refreshFiles() {
    if (!sessionId) {
      setFiles([]);
      return;
    }
    await refreshFilesFor(sessionId);
  }

  async function refreshWorkspaceTreeFor(targetSessionId: string) {
    if (!targetSessionId) {
      setWorkspaceTree(null);
      return;
    }
    const response = await fetch(
      `${API_BASE}/workspace/tree?session_id=${encodeURIComponent(targetSessionId)}`
    );
    if (!response.ok) {
      throw new Error(`Failed to load workspace tree: ${response.status}`);
    }
    const data = (await response.json()) as { root?: WorkspaceNode };
    if (latestSessionIdRef.current === targetSessionId) {
      setWorkspaceTree(data.root ?? null);
    }
  }

  async function refreshWorkspaceTree() {
    if (!sessionId) {
      setWorkspaceTree(null);
      return;
    }
    await refreshWorkspaceTreeFor(sessionId);
  }

  function scheduleWorkspaceTreeRefreshBurst(targetSessionId: string) {
    if (!targetSessionId) {
      return;
    }
    const delays = [0, 700, 1600, 3000];
    for (const delay of delays) {
      window.setTimeout(() => {
        void refreshWorkspaceTreeFor(targetSessionId).catch(() => {
          // Ignore delayed refresh failures.
        });
      }, delay);
    }
  }

  async function uploadSelectedFiles(filesToUpload: File[], targetSessionId: string) {
    if (filesToUpload.length === 0 || isUploading) {
      return;
    }

    setIsUploading(true);
    setError(null);
    try {
      await uploadFiles(filesToUpload, targetSessionId);
      await refreshFilesFor(targetSessionId);
      await refreshWorkspaceTreeFor(targetSessionId);
      setSelectedFiles(null);
      setImageDescription("");
      setShowImageDescriptionDialog(false);
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: "已上传新的用户输入文件。",
          timestamp: Date.now(),
        },
      ]);
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : "Upload failed");
    } finally {
      setIsUploading(false);
      clearFileInputValue();
    }
  }

  async function handleUpload(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isUploading) {
      return;
    }
    if (!selectedFiles || selectedFiles.length === 0) {
      fileInputRef.current?.click();
      return;
    }
    if (showImageDescriptionDialog) {
      setError("请在图片描述弹窗中点击“确认上传”。");
      return;
    }

    const targetSessionId = ensureSessionForWork();
    await uploadSelectedFiles(Array.from(selectedFiles), targetSessionId);
  }

  function handleFileInputChange(event: React.ChangeEvent<HTMLInputElement>) {
    const nextFiles = event.target.files;
    setSelectedFiles(nextFiles);

    if (hasImageFile(nextFiles)) {
      const firstImage = (nextFiles ? Array.from(nextFiles) : []).find((file) =>
        file.type.startsWith("image/") || /\.(png|jpe?g|gif|webp|bmp|svg|heic)$/i.test(file.name)
      );
      if (firstImage) {
        if (pendingImagePreviewUrl) {
          URL.revokeObjectURL(pendingImagePreviewUrl);
        }
        setPendingImageFile(firstImage);
        setPendingImagePreviewUrl(URL.createObjectURL(firstImage));
      }
      setShowImageDescriptionDialog(true);
      return;
    }

    if (pendingImagePreviewUrl) {
      URL.revokeObjectURL(pendingImagePreviewUrl);
    }
    setPendingImageFile(null);
    setPendingImagePreviewUrl("");
    setShowImageDescriptionDialog(false);
    setImageDescription("");

    // Non-image files can be uploaded immediately after selection.
    if (nextFiles && nextFiles.length > 0) {
      const targetSessionId = ensureSessionForWork();
      void uploadSelectedFiles(Array.from(nextFiles), targetSessionId);
    }
  }

  async function handleConfirmImageUpload() {
    if (!pendingImageFile || isUploading) {
      return;
    }
    const imageFile = pendingImageFile;
    const previewUrl = pendingImagePreviewUrl;
    const description = imageDescription.trim();
    if (!description) {
      setError("图片上传时请填写描述，便于写入 user_input_metadata.json。");
      return;
    }

    setIsUploading(true);
    setError(null);
    try {
      const targetSessionId = ensureSessionForWork();
      await uploadFiles([imageFile], targetSessionId, description);

      // Upload success should close dialog immediately; refresh is best-effort.
      if (previewUrl) {
        URL.revokeObjectURL(previewUrl);
      }
      setPendingImageFile(null);
      setPendingImagePreviewUrl("");
      setSelectedFiles(null);
      setShowImageDescriptionDialog(false);
      setImageDescription("");
      clearFileInputValue();

      await Promise.allSettled([
        refreshFilesFor(targetSessionId),
        refreshWorkspaceTreeFor(targetSessionId),
      ]);

      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: `已上传图片并写入描述: ${imageFile.name}`,
          timestamp: Date.now(),
        },
      ]);
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : "Upload failed");
    } finally {
      setIsUploading(false);
    }
  }

  function handleCancelImageUpload() {
    if (pendingImagePreviewUrl) {
      URL.revokeObjectURL(pendingImagePreviewUrl);
    }
    setPendingImageFile(null);
    setPendingImagePreviewUrl("");
    setSelectedFiles(null);
    setShowImageDescriptionDialog(false);
    setImageDescription("");
    clearFileInputValue();
  }

  async function handleReset() {
    if (isResetting) {
      return;
    }

    setIsResetting(true);
    setError(null);
    try {
      const response = await fetch(`${API_BASE}/reset`, {
        method: "POST",
        body: (() => {
          const formData = new FormData();
          formData.append("session_id", sessionId);
          return formData;
        })(),
      });
      const data = (await response.json()) as {
        ok?: boolean;
        stdout?: string;
        stderr?: string;
      };

      if (!response.ok || !data.ok) {
        throw new Error(data.stderr || data.stdout || `Reset failed: ${response.status}`);
      }

      await refreshFiles();
      await refreshWorkspaceTree();
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: data.stdout || "agent_workspace 已重置。",
          timestamp: Date.now(),
        },
      ]);
    } catch (resetError) {
      const message = resetError instanceof Error ? resetError.message : "Reset failed";
      setError(message);
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "error",
          text: message,
          timestamp: Date.now(),
        },
      ]);
    } finally {
      setIsResetting(false);
    }
  }

  async function handleDeleteFile(fileName: string) {
    if (!fileName || deletingFileName === fileName) {
      return;
    }

    setDeletingFileName(fileName);
    setError(null);
    try {
      const response = await fetch(
        `${API_BASE}/user-input/files/${encodeURIComponent(fileName)}?session_id=${encodeURIComponent(sessionId)}`,
        {
          method: "DELETE",
        }
      );

      if (!response.ok) {
        throw new Error(`Delete failed: ${response.status}`);
      }

      await refreshFiles();
      await refreshWorkspaceTree();
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: `已删除文件: ${fileName}`,
          timestamp: Date.now(),
        },
      ]);
    } catch (deleteError) {
      const message = deleteError instanceof Error ? deleteError.message : "Delete failed";
      setError(message);
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "error",
          text: message,
          timestamp: Date.now(),
        },
      ]);
    } finally {
      setDeletingFileName(null);
    }
  }

  function applyHitlEvent(event: HitlEvent) {
    setHitlPending(true);
    setHitlPrompt(event.prompt ?? "Agent 已暂停，等待你补充信息。");
    setHitlInput("");
    const contextText =
      event.context && Object.keys(event.context).length > 0
        ? JSON.stringify(event.context, null, 2)
        : "";
    setHitlContextText(contextText);
    setActivities((current) => [
      ...current,
      {
        id: crypto.randomUUID(),
        kind: "status",
        text: "Agent paused: waiting for human guidance.",
        timestamp: Date.now(),
      },
    ]);
  }

  async function handleSend(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const text = input.trim();
    if (!text || isSending) {
      return;
    }

    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: "user",
      text,
      status: "completed",
    };

    const placeholderAssistantId = crypto.randomUUID();
    const assistantPlaceholder: ChatMessage = {
      id: placeholderAssistantId,
      role: "assistant",
      text: "",
      status: "in_progress",
    };
    const initialConversation = [userMessage, assistantPlaceholder];

    let targetSessionId = sessionId;
    if (!targetSessionId) {
      const freshSession = createDefaultSession(sessions.length + 1);
      targetSessionId = freshSession.id;
      runtimeStatusCursorRef.current[targetSessionId] = 0;
      persistSnapshotForSession(targetSessionId, {
        messages: initialConversation,
        activities: [],
      });
      setSessions((current) => [freshSession, ...current]);
      setSessionId(targetSessionId);
      setMessages(initialConversation);
      setActivities([]);
    } else {
      setMessages((current) => [...current, ...initialConversation]);
    }

    pendingAssistantMessageIdRef.current = placeholderAssistantId;
    messageSegmentByStreamIdRef.current = {};
    lastToolByStreamIdRef.current = {};
    maybeRenameSessionFromUserInput(text, targetSessionId);
    setCenterView("conversation");
    setActivePreviewFile(null);
    setActiveWorkspacePreviewPath(null);
    setFilePreview(null);
    setFilePreviewError(null);
    setInput("");
    setError(null);
    setHitlPending(false);
    setHitlInput("");
    setIsStopping(false);
    setIsSending(true);

    try {
      const controller = new AbortController();
      streamAbortControllerRef.current = controller;
      const response = await fetch(`${API_BASE}/process-simple`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          input: [
            {
              role: "user",
              type: "message",
              content: [{ type: "text", text }],
            },
          ],
          session_id: targetSessionId,
          user_id: "frontend-user",
          stream: true,
        }),
      });

      if (!response.ok || !response.body) {
        throw new Error(`Request failed: ${response.status}`);
      }

      const decoder = new TextDecoder();
      const reader = response.body.getReader();
      await consumeSseStream(reader, decoder);
    } catch (sendError) {
      if (sendError instanceof DOMException && sendError.name === "AbortError") {
        setActivities((current) => [
          ...current,
          {
            id: crypto.randomUUID(),
            kind: "status",
            text: "已停止本次生成。",
            timestamp: Date.now(),
          },
        ]);
        setMessages((current) =>
          current.map((message) =>
            message.role === "assistant" && normalizeMessageStatus(message.status) === "in_progress"
              ? { ...message, status: "cancelled" }
              : message
          )
        );
        return;
      }
      const message = sendError instanceof Error ? sendError.message : "Request failed";
      setError(message);
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "error",
          text: message,
          timestamp: Date.now(),
        },
      ]);
    } finally {
      streamAbortControllerRef.current = null;
      setIsStopping(false);
      setIsSending(false);
      scheduleWorkspaceTreeRefreshBurst(targetSessionId);
    }
  }

  async function handleResume(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!hitlPending || isSending) {
      return;
    }

    const guidance = hitlInput.trim();
    if (!guidance) {
      setError("请先填写你的补充建议，再继续。");
      return;
    }

    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: "user",
      text: `[Human guidance] ${guidance}`,
      status: "completed",
    };

    setMessages((current) => [...current, userMessage]);
    const placeholderAssistantId = crypto.randomUUID();
    pendingAssistantMessageIdRef.current = placeholderAssistantId;
    messageSegmentByStreamIdRef.current = {};
    lastToolByStreamIdRef.current = {};
    setMessages((current) => [
      ...current,
      {
        id: placeholderAssistantId,
        role: "assistant",
        text: "",
        status: "in_progress",
      },
    ]);
    setError(null);
    setIsStopping(false);
    setIsSending(true);

    try {
      const controller = new AbortController();
      streamAbortControllerRef.current = controller;
      const response = await fetch(`${API_BASE}/process-simple`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          input: [],
          session_id: sessionId,
          user_id: "frontend-user",
          stream: true,
          resume: {
            guidance,
          },
        }),
      });

      if (!response.ok || !response.body) {
        throw new Error(`Resume request failed: ${response.status}`);
      }

      setHitlPending(false);
      setHitlInput("");

      const decoder = new TextDecoder();
      const reader = response.body.getReader();
      await consumeSseStream(reader, decoder);
    } catch (resumeError) {
      if (resumeError instanceof DOMException && resumeError.name === "AbortError") {
        setActivities((current) => [
          ...current,
          {
            id: crypto.randomUUID(),
            kind: "status",
            text: "已停止本次生成。",
            timestamp: Date.now(),
          },
        ]);
        setMessages((current) =>
          current.map((message) =>
            message.role === "assistant" && normalizeMessageStatus(message.status) === "in_progress"
              ? { ...message, status: "cancelled" }
              : message
          )
        );
        return;
      }
      const message = resumeError instanceof Error ? resumeError.message : "Resume request failed";
      setError(message);
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "error",
          text: message,
          timestamp: Date.now(),
        },
      ]);
    } finally {
      streamAbortControllerRef.current = null;
      setIsStopping(false);
      setIsSending(false);
      if (sessionId) {
        scheduleWorkspaceTreeRefreshBurst(sessionId);
      }
    }
  }

  function handleStopGeneration() {
    if (!ENABLE_STOP_GENERATION || !isSending || !streamAbortControllerRef.current) {
      return;
    }
    setIsStopping(true);
    streamAbortControllerRef.current.abort();
  }

  function upsertStatusTraceActivity(
    mergeKey: string,
    text: string,
    messageId?: string,
    timestamp = Date.now()
  ) {
    setActivities((current) => {
      const existingIndex = current.findIndex(
        (item) => item.kind === "status" && item.mergeKey === mergeKey
      );

      if (existingIndex < 0) {
        return [
          ...current,
          {
            id: crypto.randomUUID(),
            kind: "status",
            text,
            timestamp,
            messageId,
            mergeKey,
          },
        ];
      }

      return current.map((item, index) =>
        index === existingIndex
          ? {
              ...item,
              text: mergeStatusTraceText(item.text, text),
              timestamp,
              messageId,
            }
          : item
      );
    });
  }

  function applySsePayload(payload: Record<string, unknown>) {
    const simpleKind = typeof payload.kind === "string" ? payload.kind : "";
    if (simpleKind) {
      const simple = payload as SimpleStreamEvent;
      const getSegmentMessageId = (streamMsgId: string | null | undefined): string | null => {
        if (!streamMsgId) {
          return null;
        }
        return streamMsgId;
      };

      const resolveEffectiveToolLabel = (
        event: SimpleStreamEvent,
        streamMsgId: string | null | undefined
      ): string => {
        const rawLabel = getToolLabel(event);
        if (!streamMsgId) {
          return rawLabel;
        }

        const previous = lastToolByStreamIdRef.current[streamMsgId];

        // Generic "tool" updates are treated as continuation of the last specific tool.
        if (rawLabel === "tool") {
          return previous || `msg_id:${streamMsgId}`;
        }

        lastToolByStreamIdRef.current[streamMsgId] = rawLabel;
        return rawLabel;
      };

      const upsertAssistantText = (msgId: string, text: string) => {
        setMessages((current) => {
          const existing = current.find((message) => message.id === msgId);
          const placeholderId = pendingAssistantMessageIdRef.current;
          const placeholder = placeholderId ? current.find((message) => message.id === placeholderId) : undefined;

          if (!existing && placeholder) {
            pendingAssistantMessageIdRef.current = null;
            return current.map((message) =>
              message.id === placeholder.id
                ? {
                    ...message,
                    id: msgId,
                    role: "assistant",
                    text: `${message.text}${text}`,
                    status: "in_progress",
                  }
                : message
            );
          }

          if (!existing) {
            return [
              ...current,
              {
                id: msgId,
                role: "assistant",
                text,
                status: "in_progress",
              },
            ];
          }

          return current.map((message) =>
            message.id === msgId
              ? {
                  ...message,
                  text: `${message.text}${text}`,
                  status: "in_progress",
                }
              : message
          );
        });
      };

      const ensureAssistantMessage = (msgId: string) => {
        setMessages((current) => {
          const exists = current.some((message) => message.id === msgId);
          if (exists) {
            return current;
          }
          return [
            ...current,
            {
              id: msgId,
              role: "assistant",
              text: "",
              status: "in_progress",
            },
          ];
        });
      };

      if (simpleKind === "error") {
        const message = typeof simple.text === "string" && simple.text ? simple.text : "Unknown runtime error";
        setActivities((current) => [
          ...current,
          {
            id: crypto.randomUUID(),
            kind: "error",
            text: message,
            timestamp: Date.now(),
          },
        ]);
        return;
      }

      if (simpleKind === "hitl") {
        const event = simple.payload;
        if (event && typeof event === "object") {
          applyHitlEvent(event);
        }
        return;
      }

      if (simpleKind === "tool" || simpleKind === "tool_call_update") {
        const streamMsgId = typeof simple.msg_id === "string" && simple.msg_id ? simple.msg_id : null;
        if (!streamMsgId) {
          return;
        }
        const rawToolLabel = getToolLabel(simple);
        const effectiveToolLabel = resolveEffectiveToolLabel(simple, streamMsgId);
        const msgId = getSegmentMessageId(streamMsgId) || undefined;
        if (msgId) {
          ensureAssistantMessage(msgId);
        }
        const provisionalToolLabel = `msg_id:${streamMsgId}`;
        const provisionalMergeKey = `${msgId ?? "pending"}::${provisionalToolLabel}`;
        const mergeKey = `${msgId ?? "pending"}::${effectiveToolLabel}`;
        setActivities((current) => {
          const existingIndex = current.findIndex(
            (item) => item.kind === "tool" && item.mergeKey === mergeKey
          );

          // If earlier chunks for the same msg_id were provisionally grouped, fold them into
          // the concrete tool group as soon as we learn the specific tool name.
          const provisionalIndex = current.findIndex(
            (item) => item.kind === "tool" && item.mergeKey === provisionalMergeKey
          );

          let working = current;
          let targetIndex = existingIndex;

          if (
            effectiveToolLabel !== provisionalToolLabel &&
            provisionalIndex >= 0
          ) {
            if (existingIndex >= 0) {
              const existingItem = current[existingIndex];
              const provisionalItem = current[provisionalIndex];
              const mergedArgs = buildToolArgsStream(existingItem.toolArgsStream, provisionalItem.toolArgsStream);
              const mergedText = formatToolActivityText(
                {
                  ...simple,
                  args: mergedArgs ?? simple.args,
                },
                ENABLE_VERBOSE_TRACE,
                effectiveToolLabel
              );

              working = current
                .filter((_, index) => index !== provisionalIndex)
                .map((item, index) => {
                  const adjustedExistingIndex = provisionalIndex < existingIndex ? existingIndex - 1 : existingIndex;
                  if (index !== adjustedExistingIndex) {
                    return item;
                  }
                  return {
                    ...item,
                    text: mergedText || item.text,
                    timestamp: Math.max(item.timestamp, provisionalItem.timestamp),
                    startedAt: Math.min(item.startedAt ?? item.timestamp, provisionalItem.startedAt ?? provisionalItem.timestamp),
                    toolArgsStream: mergedArgs,
                    toolLabel: effectiveToolLabel,
                    toolSummary: extractToolSummaryFromText(mergedText || item.text),
                    hasGenericToolChild: item.hasGenericToolChild || provisionalItem.hasGenericToolChild || rawToolLabel === "tool",
                  };
                });
              targetIndex = provisionalIndex < existingIndex ? existingIndex - 1 : existingIndex;
            } else {
              working = current.map((item, index) =>
                index === provisionalIndex
                  ? {
                      ...item,
                      mergeKey,
                      toolLabel: effectiveToolLabel,
                      hasGenericToolChild: item.hasGenericToolChild || rawToolLabel === "tool",
                    }
                  : item
              );
              targetIndex = provisionalIndex;
            }
          }

          if (targetIndex < 0) {
            const toolArgsStream = buildToolArgsStream(undefined, simple.args);
            const text = formatToolActivityText(
              {
                ...simple,
                args: toolArgsStream ?? simple.args,
              },
              ENABLE_VERBOSE_TRACE,
              effectiveToolLabel
            );
            if (!text) {
              return working;
            }
            return [
              ...working,
              {
                id: crypto.randomUUID(),
                kind: "tool",
                text,
                timestamp: Date.now(),
                startedAt: Date.now(),
                messageId: msgId,
                mergeKey,
                toolArgsStream,
                toolLabel: effectiveToolLabel,
                toolSummary: extractToolSummaryFromText(text),
                hasGenericToolChild: rawToolLabel === "tool",
              },
            ];
          }

          return working.map((item, index) => {
            if (index !== targetIndex) {
              return item;
            }

            const nextToolArgsStream = buildToolArgsStream(item.toolArgsStream, simple.args);
            const nextText = formatToolActivityText(
              {
                ...simple,
                args: nextToolArgsStream ?? simple.args,
              },
              ENABLE_VERBOSE_TRACE,
              effectiveToolLabel
            );

            return {
              ...item,
              text: nextText || item.text,
              timestamp: Date.now(),
              startedAt: item.startedAt ?? item.timestamp,
              messageId: msgId,
              toolArgsStream: nextToolArgsStream,
              toolLabel: effectiveToolLabel,
              toolSummary: extractToolSummaryFromText(nextText || item.text),
              hasGenericToolChild: item.hasGenericToolChild || rawToolLabel === "tool",
            };
          });
        });
        return;
      }

      if (simpleKind === "status" || simpleKind === "status_update") {
        const rawStatusText = typeof simple.text === "string" ? simple.text : "";
        if (!isExecutionStatusText(rawStatusText)) {
          return;
        }
        const preview = extractPreviewText(rawStatusText);
        if (!preview) {
          return;
        }
        const streamMsgId = typeof simple.msg_id === "string" && simple.msg_id ? simple.msg_id : null;
        if (!streamMsgId) {
          return;
        }
        const msgId = getSegmentMessageId(streamMsgId) || undefined;
        if (msgId) {
          ensureAssistantMessage(msgId);
        }
        const mergeKey = `status-preview::${msgId ?? "pending"}`;
        upsertStatusTraceActivity(mergeKey, `preview: ${preview}`, msgId, Date.now());
        return;
      }

      if (simpleKind === "text" || simpleKind === "doc" || simpleKind === "assistant_text" || simpleKind === "assistant_doc") {
        const streamMsgId = typeof simple.msg_id === "string" && simple.msg_id ? simple.msg_id : null;
        const msgId = getSegmentMessageId(streamMsgId);
        const text = typeof simple.text === "string" ? simple.text : "";
        if (!msgId || !text) {
          return;
        }
        upsertAssistantText(msgId, text);
        return;
      }

      // Forward-compatible fallback: accept other text-like kinds from backend.
      if (
        simpleKind === "message" ||
        simpleKind === "assistant" ||
        simpleKind === "output_text" ||
        simpleKind === "token"
      ) {
        const streamMsgId = typeof simple.msg_id === "string" && simple.msg_id ? simple.msg_id : null;
        const msgId = getSegmentMessageId(streamMsgId);
        const text = typeof simple.text === "string" ? simple.text : "";
        if (!msgId || !text) {
          return;
        }
        upsertAssistantText(msgId, text);
        return;
      }

      if (simpleKind === "done") {
        setMessages((current) =>
          current.map((message) =>
            message.role === "assistant" && normalizeMessageStatus(message.status) === "in_progress"
              ? { ...message, status: "completed" }
              : message
          )
        );
        return;
      }
    }
  }

  async function consumeSseStream(
    reader: ReadableStreamDefaultReader<Uint8Array>,
    decoder: TextDecoder
  ) {
    let buffer = "";
    let pendingJsonPayload = "";

    const emitStreamStatus = (text: string) => {
      if (!isExecutionStatusText(text)) {
        return;
      }
      const snippet = extractPreviewText(text).slice(0, 200);
      if (!snippet) {
        return;
      }
      upsertStatusTraceActivity("status-preview::stream", `preview: ${snippet}`, undefined, Date.now());
    };

    const tryParseAndApply = (raw: string): boolean => {
      const trimmed = raw.trim();
      if (!trimmed || trimmed === "[DONE]") {
        return true;
      }
      try {
        const payload = JSON.parse(trimmed) as Record<string, unknown>;
        applySsePayload(payload);
        return true;
      } catch {
        return false;
      }
    };

    const processLine = (line: string) => {
      if (line.startsWith("data:")) {
        const dataLine = line.slice(5).trimStart();
        if (!dataLine || dataLine === "[DONE]") {
          return;
        }

        // Prefer immediate per-line parse for real-time rendering.
        if (tryParseAndApply(dataLine)) {
          pendingJsonPayload = "";
          return;
        }

        // Fallback: assemble multi-line JSON fragments when needed.
        pendingJsonPayload = pendingJsonPayload
          ? `${pendingJsonPayload}\n${dataLine}`
          : dataLine;

        if (tryParseAndApply(pendingJsonPayload)) {
          pendingJsonPayload = "";
        }
        return;
      }

      if (!line.trim()) {
        if (pendingJsonPayload) {
          if (!tryParseAndApply(pendingJsonPayload)) {
            emitStreamStatus(pendingJsonPayload);
          }
          pendingJsonPayload = "";
        }
        return;
      }

      emitStreamStatus(line);
    };

    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() ?? "";

      for (const line of lines) {
        processLine(line);
      }
    }

    const tail = buffer.trim();
    if (tail) {
      processLine(tail);
    }

    if (pendingJsonPayload) {
      if (!tryParseAndApply(pendingJsonPayload)) {
        emitStreamStatus(pendingJsonPayload);
      }
    }
  }

  function renderWorkspaceNode(node: WorkspaceNode, depth = 0): JSX.Element {
    if (node.type === "directory") {
      return (
        <details className="tree-node tree-directory" key={node.path} open={depth < 2}>
          <summary>
            <span className="tree-name">{node.name}</span>
            <span className="tree-path">{node.path}</span>
          </summary>
          <div className="tree-children">
            {node.children && node.children.length > 0 ? (
              node.children.map((child) => renderWorkspaceNode(child, depth + 1))
            ) : (
              <div className="tree-empty">空目录</div>
            )}
          </div>
        </details>
      );
    }

    const uploadedUserInputFile = files.find((file) => file.path === node.path);
    const canDeleteUploadedFile = Boolean(uploadedUserInputFile && node.path.startsWith("/user_input/"));
    const isDeletingUploadedFile = Boolean(
      uploadedUserInputFile && deletingFileName === uploadedUserInputFile.name
    );

    return (
      <div
        className={`tree-node tree-file ${centerView === "file-preview" && activeWorkspacePreviewPath === node.path ? "active" : ""}`}
        key={node.path}
        role="button"
        tabIndex={0}
        onClick={() => void handlePreviewWorkspaceFile(node)}
        onKeyDown={(event) => {
          if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            void handlePreviewWorkspaceFile(node);
          }
        }}
      >
        <span className="tree-name">{node.name}</span>
        <span className="tree-path">{node.path}</span>
        <span className="tree-file-actions">
          <span className="tree-size">{typeof node.size === "number" ? formatBytes(node.size) : ""}</span>
          {canDeleteUploadedFile && uploadedUserInputFile ? (
            <button
              className="tree-file-delete-button"
              type="button"
              disabled={isDeletingUploadedFile}
              onClick={(event) => {
                event.stopPropagation();
                void handleDeleteFile(uploadedUserInputFile.name);
              }}
            >
              {isDeletingUploadedFile ? "..." : "删除"}
            </button>
          ) : null}
        </span>
      </div>
    );
  }

  const previewDisplayName =
    activePreviewFile?.name ??
    (activeWorkspacePreviewPath
      ? activeWorkspacePreviewPath.split("/").filter(Boolean).pop() ?? activeWorkspacePreviewPath
      : "未选择文件");

  const visibleMessages = messages.filter((message) => {
    if (message.role === "user") {
      return true;
    }
    if (message.role === "assistant") {
      const hasContent = message.text && message.text.trim().length > 0;
      const hasTool = activities.some((item) => item.kind === "tool" && item.messageId === message.id);
      return hasContent || hasTool;
    }
    return true;
  });
  const latestAssistantMessageId = [...visibleMessages]
    .reverse()
    .find((message) => message.role === "assistant")?.id;
  const headerStatusTone = isSending ? "running" : hitlPending ? "waiting" : "ready";
  const headerStatusLabel = isSending ? "Running" : hitlPending ? "Waiting" : "Ready";
  const sortedSessions = [...sessions].sort((a, b) => b.createdAt - a.createdAt);
  const todayStart = (() => {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  })();
  const weekStart = todayStart - 6 * 24 * 60 * 60 * 1000;
  const sessionGroups = [
    {
      label: "今天",
      items: sortedSessions.filter((item) => item.createdAt >= todayStart),
    },
    {
      label: "过去 7 天",
      items: sortedSessions.filter((item) => item.createdAt < todayStart && item.createdAt >= weekStart),
    },
    {
      label: "更早",
      items: sortedSessions.filter((item) => item.createdAt < weekStart),
    },
  ].filter((group) => group.items.length > 0);
  const composerPlaceholder =
    files.length > 0
      ? `已收到素材 ${files[0].name}${files.length > 1 ? ` 等 ${files.length} 个文件` : ""}，请简单描述你想生成的页面效果。`
      : PROMPT_EXAMPLES[promptExampleIndex];
  const isLandingMode = !sessionId;
  const activeSessionTitle = sessions.find((item) => item.id === sessionId)?.title ?? "未命名会话";
  const compactSessionTitle =
    activeSessionTitle.length > 18 ? `${activeSessionTitle.slice(0, 18)}...` : activeSessionTitle;

  return (
    <>
      {pendingDeleteSession ? (
        <div className="modal-backdrop" role="presentation" onClick={cancelDeleteSession}>
          <div className="delete-session-dialog" role="dialog" aria-modal="true" aria-label="删除会话确认" onClick={(event) => event.stopPropagation()}>
            <div className="panel-label">Delete Session</div>
            <h3>确认删除这个会话？</h3>
            <p className="muted">
              会话“{pendingDeleteSession.title}”及其本地历史记录将被移除，这个操作无法撤销。
            </p>
            <div className="dialog-actions">
              <button className="secondary-button" type="button" onClick={cancelDeleteSession}>
                取消
              </button>
              <button className="danger-button" type="button" onClick={confirmDeleteSession}>
                确认删除
              </button>
            </div>
          </div>
        </div>
      ) : null}

      <main className={`app-shell ${simulatorCollapsed ? "simulator-collapsed" : ""}`}>
      <aside className="left-panel">
        <section className="panel-card hero-card">
          <div className="left-brand">
            <div className="session-title-line">
              <span className="session-title-icon" aria-hidden="true">◈</span>
              <h2 className="left-brand-name">ImageToArkTS</h2>
            </div>
            <p className="left-brand-subline">HarmonyOS 原型生成系统</p>
          </div>
          <div className="session-header-row">
            <button
              className="session-create-icon"
              type="button"
              onClick={handleCreateSession}
              aria-label="新建会话"
              title="新建会话"
            >
              +
            </button>
          </div>
          <div className="session-list" aria-label="session-list">
            {sessionGroups.map((group) => (
              <div className="session-group" key={group.label}>
                <div className="session-group-label">{group.label}</div>
                {group.items.map((item) => (
                  <div
                    key={item.id}
                    className={`session-list-item ${centerView === "conversation" && item.id === sessionId ? "active" : ""}`}
                    role="button"
                    tabIndex={0}
                    onClick={() => handleSwitchSession(item.id)}
                    onKeyDown={(event) => {
                      if (event.key === "Enter" || event.key === " ") {
                        event.preventDefault();
                        handleSwitchSession(item.id);
                      }
                    }}
                  >
                    <span className="session-list-main">
                      <span className="session-list-title">{item.title}</span>
                      <span className="session-list-meta">{item.id.slice(0, 8)}</span>
                    </span>
                    <div
                      className={`session-item-actions ${openSessionMenuId === item.id ? "open" : ""}`}
                      onPointerDown={(event) => event.stopPropagation()}
                      onClick={(event) => event.stopPropagation()}
                    >
                      <button
                        className="session-item-more"
                        type="button"
                        aria-label={`会话操作 ${item.title}`}
                        aria-expanded={openSessionMenuId === item.id}
                        onClick={(event) => {
                          event.stopPropagation();
                          setOpenSessionMenuId((current) => (current === item.id ? null : item.id));
                        }}
                      >
                        ⋯
                      </button>
                      <div className="session-item-menu" role="menu" aria-label="会话操作菜单">
                        <button
                          className="session-item-menu-button"
                          type="button"
                          role="menuitem"
                          onClick={(event) => {
                            event.stopPropagation();
                            requestRenameSession(item.id);
                          }}
                        >
                          重命名
                        </button>
                        <button
                          className="session-item-menu-button danger"
                          type="button"
                          role="menuitem"
                          onClick={(event) => {
                            event.stopPropagation();
                            requestDeleteSession(item.id);
                          }}
                        >
                          删除
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </section>

        <section className={`panel-card context-card ${showImageDescriptionDialog ? "dialog-open" : ""}`}>
          <div className="panel-row">
            <div className="panel-label">当前任务上下文</div>
            <button className="secondary-button" disabled={isResetting || isLandingMode} type="button" onClick={handleReset}>
              {isResetting ? "Resetting..." : "Reset"}
            </button>
          </div>
          <form className="context-upload-bar" onSubmit={handleUpload}>
            <input
              id="file-input"
              type="file"
              ref={fileInputRef}
              onChange={handleFileInputChange}
              style={{ display: "none" }}
            />
            <button className="context-upload-button" disabled={isUploading || showImageDescriptionDialog} type="submit">
              + 添加文件
            </button>
            <span className="context-upload-meta">
              {isLandingMode
                ? "可直接添加文件，首次上传会自动创建会话"
                : files.length > 0
                  ? `当前已加载 ${files.length} 个文件`
                  : "上传后会自动进入当前项目文件树"}
            </span>
          </form>

          {showImageDescriptionDialog ? (
            <div className="image-desc-dialog">
              <div className="panel-label">Image Description</div>
              {pendingImageFile ? <p className="file-path">待上传: {pendingImageFile.name}</p> : null}
              <textarea
                value={imageDescription}
                onChange={(event) => setImageDescription(event.target.value)}
                placeholder="例如：这是一张计算器主界面草图，上方是表达式显示区，下方是数字键盘。"
                rows={3}
              />
              <div className="dialog-actions">
                <button
                  className="secondary-button image-dialog-action"
                  type="button"
                  onClick={handleCancelImageUpload}
                >
                  取消
                </button>
                <button
                  className="secondary-button image-dialog-action"
                  type="button"
                  disabled={isUploading || !pendingImageFile || !imageDescription.trim()}
                  onClick={() => void handleConfirmImageUpload()}
                >
                  {isUploading ? "上传中..." : "确认"}
                </button>
              </div>
            </div>
          ) : null}

          <p className="muted">当前项目文件会在上传后自动更新，可直接点击预览并按需删除。</p>
          <div className="context-tree-title">当前项目文件 ({files.length})</div>
          <div className="workspace-tree">
            {workspaceTree
              ? renderWorkspaceNode(workspaceTree)
              : isLandingMode && files.length === 0
                ? <p className="muted">暂无文件</p>
                : null}
          </div>
        </section>

      </aside>

      <section className="chat-panel">
        {isLandingMode ? (
          <div className="landing-shell">
            <div className="landing-welcome">
              <div className="session-title-line landing-title-line">
                <span className="session-title-icon" aria-hidden="true">◈</span>
                <h2>欢迎使用 ImageToArkTS</h2>
              </div>
              <p className="chat-header-subline">请先输入你的需求，发送后将自动创建新会话并进入正式工作区。</p>
            </div>

            <form className="composer composer-landing" onSubmit={handleSend}>
              <div className="prompt-template-row">
                {PROMPT_TEMPLATES.map((template) => (
                  <button
                    key={template}
                    className="prompt-template-button"
                    type="button"
                    onClick={() => setInput(template)}
                  >
                    {template}
                  </button>
                ))}
              </div>
              <textarea
                rows={3}
                value={input}
                onChange={(event) => setInput(event.target.value)}
                placeholder={PROMPT_EXAMPLES[promptExampleIndex]}
              />
              <div className="composer-footer">
                <div className="muted">上传设计稿或需求文档，为您生成应用。</div>
                <div className="composer-actions">
                  <button disabled={isSending || !input.trim()} type="submit">
                    {isSending ? "Running..." : "Send"}
                  </button>
                </div>
              </div>
            </form>
          </div>
        ) : null}

        {!isLandingMode ? (
          <>
        <header className="chat-header">
          <div className="session-header-main">
            <div className="session-title-line">
              <span className="session-title-icon" aria-hidden="true">◈</span>
              <h2 className="chat-session-name">{compactSessionTitle}</h2>
            </div>
            <p className="chat-header-subline">当前会话（{sessionId.slice(0, 8)}）</p>
          </div>
          <div className={`header-chip header-chip-${headerStatusTone}`}>
            <span className="status-dot" aria-hidden="true" />
            {headerStatusLabel}
          </div>
        </header>

        <div className="chat-scroll" ref={scrollRef}>
          {centerView === "file-preview" ? (
            <section className="file-preview-card">
              <div className="panel-label">File Preview</div>
              <h3>{previewDisplayName}</h3>
              {isPreviewLoading ? <p className="muted">正在加载预览...</p> : null}
              {filePreviewError ? <p className="preview-error">{filePreviewError}</p> : null}
              {!isPreviewLoading && !filePreviewError && filePreview?.kind === "image" && filePreview.data_url ? (
                <img className="file-preview-image" src={filePreview.data_url} alt={filePreview.name ?? "preview"} />
              ) : null}
              {!isPreviewLoading && !filePreviewError && filePreview?.kind === "text" ? (
                <>
                  <pre className="file-preview-text">{filePreview.text ?? ""}</pre>
                  {filePreview.truncated ? <p className="muted">内容过长，已截断展示。</p> : null}
                </>
              ) : null}
              {!isPreviewLoading && !filePreviewError && filePreview?.kind === "binary" ? (
                <p className="muted">该文件类型暂不支持预览（{filePreview.content_type ?? "unknown"}）。</p>
              ) : null}
              {!isPreviewLoading && !filePreviewError && !filePreview ? (
                <p className="muted">点击左侧文件可查看预览。</p>
              ) : null}
            </section>
          ) : null}

          {centerView === "conversation" ? visibleMessages.map((message) => {
            const isAssistant = message.role === "assistant";
            const inlineTools = isAssistant
              ? activities
                  .filter(
                    (item) =>
                      item.kind === "tool" &&
                      (item.messageId === message.id ||
                        (!!message.runId && !item.messageId && item.runId === message.runId))
                  )
                  .sort((a, b) => a.timestamp - b.timestamp)
              : [];

            const mergedTools = inlineTools;


            return (
              <div className={`message-row message-${message.role}`} key={message.id}>
                <div className="message-stack">
                  <article className="message-card">
                    <div className="message-meta">
                      <span>{message.role === "user" ? "You" : "Agent"}</span>
                      <span className={`status-badge status-${normalizeMessageStatus(message.status)}`}>
                        {getMessageStatusLabel(message.status)}
                      </span>
                    </div>

                    {renderMessageBody(message)}
                  </article>

                  {isAssistant && mergedTools.length > 0 ? (
                    <div className="tool-structured-panels">
                      <div className="inline-tool-list">
                        {mergedTools.map((item) => {
                          const parentToolLabel = item.toolLabel || getActivityToolLabel(item);
                          const detailMarkdown = buildToolDetailMarkdown(item.toolArgsStream, "");
                          const elapsedText = formatDurationMs(
                            (item.timestamp ?? Date.now()) - (item.startedAt ?? item.timestamp ?? Date.now())
                          );
                          const shouldOpen = false;

                          return (
                            <details className="inline-tool-item execution-tool-item" key={item.id} open={shouldOpen}>
                              <summary className="tool-parent-line">
                                <span>tool={parentToolLabel}</span>
                                <span className="activity-time">{new Date(item.timestamp).toLocaleTimeString()} · 耗时 {elapsedText}</span>
                              </summary>
                              {detailMarkdown ? (
                                <div className="tool-child-content markdown-body tool-markdown-body">
                                  <ReactMarkdown remarkPlugins={[remarkGfm]}>{detailMarkdown}</ReactMarkdown>
                                </div>
                              ) : null}
                            </details>
                          );
                        })}
                      </div>
                    </div>
                  ) : null}
                </div>
              </div>
            );
          }) : null}
        </div>

        {hitlPending ? (
          <section className="hitl-card">
            <div className="panel-label">Human-in-the-loop</div>
            <h3>Agent 需要你的补充信息</h3>
            <p className="muted">{hitlPrompt}</p>
            {hitlContextText ? (
              <pre className="hitl-context">{hitlContextText}</pre>
            ) : null}
            <form className="hitl-form" onSubmit={handleResume}>
              <textarea
                rows={4}
                value={hitlInput}
                onChange={(event) => setHitlInput(event.target.value)}
                placeholder="例如：允许临时简化布局，先保证主页面可编译；某个组件改成静态文本。"
              />
              <div className="composer-footer">
                <div className="muted">提交后会在同一 session 内继续执行。</div>
                <button disabled={isSending || !hitlInput.trim()} type="submit">
                  {isSending ? "Resuming..." : "继续执行"}
                </button>
              </div>
            </form>
          </section>
        ) : null}

        <form className="composer" onSubmit={handleSend}>
          <div className="prompt-template-row">
            {PROMPT_TEMPLATES.map((template) => (
              <button
                key={template}
                className="prompt-template-button"
                type="button"
                onClick={() => setInput(template)}
              >
                {template}
              </button>
            ))}
          </div>
          <textarea
            rows={3}
            value={input}
            onChange={(event) => setInput(event.target.value)}
            placeholder={composerPlaceholder}
          />
          <div className="composer-footer">
            <div className="muted">{error ?? "聊天请求会直接发送到 /process"}</div>
            <div className="composer-actions">
              {ENABLE_STOP_GENERATION ? (
                <button
                  className="secondary-button"
                  type="button"
                  disabled={!isSending || isStopping}
                  onClick={handleStopGeneration}
                >
                  {isStopping ? "Stopping..." : "Stop"}
                </button>
              ) : null}
              <button disabled={isSending || !input.trim()} type="submit">
                {isSending ? "Running..." : "Send"}
              </button>
            </div>
          </div>
        </form>
          </>
        ) : null}
      </section>

      <aside
        className={`simulator-panel ${simulatorCollapsed ? "collapsed" : ""}`}
        aria-label="simulator-reserved-space"
      >
        <button
          type="button"
          className="simulator-handle"
          onClick={() => setSimulatorCollapsed(!simulatorCollapsed)}
          aria-label={simulatorCollapsed ? "展开模拟器区域" : "折叠模拟器区域"}
          title={simulatorCollapsed ? "展开" : "折叠"}
        >
          <span className="simulator-handle-icon" aria-hidden="true">
            {simulatorCollapsed ? "◀" : "▶"}
          </span>
        </button>
        <div className="simulator-placeholder">
          {!simulatorCollapsed ? (
            <>
              <div className="panel-label">Simulator</div>
              <p className="muted">预留区域：后续用于放置 HarmonyOS 模拟器预览。</p>
            </>
          ) : null}
        </div>
      </aside>
      </main>
    </>
  );
}
