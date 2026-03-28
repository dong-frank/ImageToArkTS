import { useEffect, useRef, useState } from "react";

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
  messageId?: string;
  runId?: string;
};

type WorkspaceNode = {
  name: string;
  path: string;
  type: "directory" | "file";
  size?: number;
  children?: WorkspaceNode[];
};

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "http://127.0.0.1:8080";
const HITL_EVENT_PREFIX = "__HITL_REQUIRED__:";

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

function extractTextFromContent(content: unknown): string {
  if (!Array.isArray(content)) {
    return "";
  }

  const chunks: string[] = [];
  for (const item of content) {
    if (typeof item === "string") {
      chunks.push(item);
      continue;
    }

    if (!item || typeof item !== "object") {
      continue;
    }

    const directText = (item as { text?: unknown }).text;
    if (typeof directText === "string" && directText.trim().length > 0) {
      chunks.push(directText);
    }

    const nestedText = extractTextFromContent((item as { content?: unknown }).content);
    if (nestedText) {
      chunks.push(nestedText);
    }
  }

  return chunks.join("");
}

function buildToolActivityText(data: Record<string, unknown> | undefined): string {
  if (!data) {
    return "tool call";
  }

  const toolName = typeof data.name === "string" ? data.name : "tool";
  const candidateInput = (data.arguments ?? data.input ?? data.params) as unknown;
  if (candidateInput === undefined) {
    return `tool call: ${toolName}`;
  }

  const raw =
    typeof candidateInput === "string"
      ? candidateInput
      : (() => {
          try {
            return JSON.stringify(candidateInput);
          } catch {
            return "";
          }
        })();

  if (!raw) {
    return `tool call: ${toolName}`;
  }

  const brief = raw.length > 180 ? `${raw.slice(0, 180)}...` : raw;
  return `tool call: ${toolName} | args: ${brief}`;
}

function hasRenderableMessageText(message: ChatMessage): boolean {
  if (message.role === "user") {
    return true;
  }
  return message.text.trim().length > 0;
}

function tryReadString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function extractRunId(source: Record<string, unknown> | undefined): string | undefined {
  if (!source) {
    return undefined;
  }

  const direct =
    tryReadString(source.run_id) ??
    tryReadString(source.runId) ??
    tryReadString(source.response_id) ??
    tryReadString(source.responseId);
  if (direct) {
    return direct;
  }

  const response = source.response;
  if (response && typeof response === "object") {
    const nestedId = tryReadString((response as { id?: unknown }).id);
    if (nestedId) {
      return nestedId;
    }
  }

  if (source.object === "response") {
    return tryReadString(source.id);
  }

  return undefined;
}

function bindPendingToolsForRunToMessage(
  activities: ActivityItem[],
  runId: string,
  messageId: string
): ActivityItem[] {
  let hasChanges = false;
  const next = activities.map((item) => {
    if (item.kind === "tool" && item.runId === runId && !item.messageId) {
      hasChanges = true;
      return { ...item, messageId };
    }
    return item;
  });
  return hasChanges ? next : activities;
}

function parseHitlEvent(text: string): HitlEvent | null {
  const raw = text.trim();
  if (!raw.startsWith(HITL_EVENT_PREFIX)) {
    return null;
  }
  const payloadText = raw.slice(HITL_EVENT_PREFIX.length).trim();
  if (!payloadText) {
    return null;
  }
  try {
    const parsed = JSON.parse(payloadText) as HitlEvent;
    if (!parsed || typeof parsed !== "object") {
      return null;
    }
    if (!parsed.hitl_required) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

export default function App() {
  const [sessions, setSessions] = useState<SessionItem[]>(() => {
    const stored = readSessionList();
    if (stored.length > 0) {
      return stored;
    }
    return [createDefaultSession(1)];
  });
  const [sessionId, setSessionId] = useState(() => {
    const stored = readSessionList();
    const candidates = stored.length > 0 ? stored : [createDefaultSession(1)];
    return readActiveSessionId(candidates);
  });
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
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const latestAssistantMessageIdRef = useRef<string | null>(null);
  const currentRunIdRef = useRef<string | null>(null);
  const runToMessageIdRef = useRef<Record<string, string>>({});
  const messageToRunIdRef = useRef<Record<string, string>>({});
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    const exists = sessions.some((item) => item.id === sessionId);
    if (!exists && sessions.length > 0) {
      setSessionId(sessions[0].id);
    }
  }, [sessions, sessionId]);

  useEffect(() => {
    persistSessionList(sessions);
  }, [sessions]);

  useEffect(() => {
    persistActiveSessionId(sessionId);
  }, [sessionId]);

  useEffect(() => {
    const snapshot = readSnapshotForSession(sessionId);
    setMessages(snapshot?.messages ?? []);
    setActivities(snapshot?.activities ?? []);
    setInput("");
    setError(null);
    setHitlPending(false);
    setHitlPrompt("");
    setHitlContextText("");
    setHitlInput("");
    currentRunIdRef.current = null;
    latestAssistantMessageIdRef.current = null;
    runToMessageIdRef.current = {};
    messageToRunIdRef.current = {};
    void refreshFiles();
    void refreshWorkspaceTree();
  }, [sessionId]);

  useEffect(() => {
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
      behavior: "smooth",
    });
  }, [messages, activities]);

  useEffect(() => {
    return () => {
      if (pendingImagePreviewUrl) {
        URL.revokeObjectURL(pendingImagePreviewUrl);
      }
    };
  }, [pendingImagePreviewUrl]);

  function clearFileInputValue() {
    const fileInput = fileInputRef.current;
    if (fileInput) {
      fileInput.value = "";
    }
  }

  function handleCreateSession() {
    setSessions((current) => {
      const next = [createDefaultSession(current.length + 1), ...current];
      setSessionId(next[0].id);
      return next;
    });
  }

  function handleSwitchSession(nextSessionId: string) {
    if (!nextSessionId || nextSessionId === sessionId) {
      return;
    }
    setSessionId(nextSessionId);
  }

  function maybeRenameSessionFromUserInput(text: string) {
    const cleaned = text.trim();
    if (!cleaned) {
      return;
    }
    const title = cleaned.length > 24 ? `${cleaned.slice(0, 24)}...` : cleaned;
    setSessions((current) =>
      current.map((item) => {
        if (item.id !== sessionId) {
          return item;
        }
        if (!item.title.startsWith("新会话")) {
          return { ...item, updatedAt: Date.now() };
        }
        return { ...item, title, updatedAt: Date.now() };
      })
    );
  }

  async function uploadFiles(filesToUpload: File[], description = "") {
    const formData = new FormData();
    for (const file of filesToUpload) {
      formData.append("files", file);
    }
    formData.append("session_id", sessionId);
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

  async function refreshFiles() {
    const response = await fetch(
      `${API_BASE}/user-input/files?session_id=${encodeURIComponent(sessionId)}`
    );
    if (!response.ok) {
      throw new Error(`Failed to list files: ${response.status}`);
    }
    const data = (await response.json()) as { files: UploadedFile[] };
    setFiles(data.files ?? []);
  }

  async function refreshWorkspaceTree() {
    const response = await fetch(
      `${API_BASE}/workspace/tree?session_id=${encodeURIComponent(sessionId)}`
    );
    if (!response.ok) {
      throw new Error(`Failed to load workspace tree: ${response.status}`);
    }
    const data = (await response.json()) as { root?: WorkspaceNode };
    setWorkspaceTree(data.root ?? null);
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

    setIsUploading(true);
    setError(null);
    try {
      await uploadFiles(Array.from(selectedFiles));

      await refreshFiles();
      await refreshWorkspaceTree();
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
  }

  async function handleConfirmImageUpload() {
    if (!pendingImageFile || isUploading) {
      return;
    }
    const description = imageDescription.trim();
    if (!description) {
      setError("图片上传时请填写描述，便于写入 user_input_metadata.json。");
      return;
    }

    setIsUploading(true);
    setError(null);
    try {
      await uploadFiles([pendingImageFile], description);
      await refreshFiles();
      await refreshWorkspaceTree();
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: `已上传图片并写入描述: ${pendingImageFile.name}`,
          timestamp: Date.now(),
        },
      ]);
      if (pendingImagePreviewUrl) {
        URL.revokeObjectURL(pendingImagePreviewUrl);
      }
      setPendingImageFile(null);
      setPendingImagePreviewUrl("");
      setSelectedFiles(null);
      setShowImageDescriptionDialog(false);
      setImageDescription("");
      clearFileInputValue();
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : "Upload failed");
    } finally {
      setIsUploading(false);
    }
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

    setMessages((current) => [...current, userMessage]);
    maybeRenameSessionFromUserInput(text);
    setInput("");
    setError(null);
    setHitlPending(false);
    setHitlInput("");
    setIsSending(true);

    try {
      const response = await fetch(`${API_BASE}/process`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          input: [
            {
              role: "user",
              type: "message",
              content: [{ type: "text", text }],
            },
          ],
          session_id: sessionId,
          user_id: "frontend-user",
          stream: true,
        }),
      });

      if (!response.ok || !response.body) {
        throw new Error(`Request failed: ${response.status}`);
      }

      const decoder = new TextDecoder();
      const reader = response.body.getReader();
      let buffer = "";

      const processEventBlock = (block: string) => {
        const dataLines = block
          .split("\n")
          .filter((line) => line.startsWith("data:"))
          .map((line) => line.slice(5).trimStart());

        if (dataLines.length === 0) {
          return;
        }

        const joined = dataLines.join("\n").trim();
        if (!joined || joined === "[DONE]") {
          return;
        }

        try {
          const payload = JSON.parse(joined) as Record<string, unknown>;
          applySsePayload(payload);
        } catch {
          setActivities((current) => [
            ...current,
            {
              id: crypto.randomUUID(),
              kind: "error",
              text: "收到无法解析的流式数据片段。",
              timestamp: Date.now(),
            },
          ]);
        }
      };

      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const parts = buffer.split("\n\n");
        buffer = parts.pop() ?? "";

        for (const part of parts) {
          processEventBlock(part);
        }
      }

      if (buffer.trim()) {
        processEventBlock(buffer);
      }
    } catch (sendError) {
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
      setIsSending(false);
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
    setError(null);
    setIsSending(true);

    try {
      const response = await fetch(`${API_BASE}/process`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
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
      let buffer = "";

      const processEventBlock = (block: string) => {
        const dataLines = block
          .split("\n")
          .filter((line) => line.startsWith("data:"))
          .map((line) => line.slice(5).trimStart());

        if (dataLines.length === 0) {
          return;
        }

        const joined = dataLines.join("\n").trim();
        if (!joined || joined === "[DONE]") {
          return;
        }

        try {
          const payload = JSON.parse(joined) as Record<string, unknown>;
          applySsePayload(payload);
        } catch {
          setActivities((current) => [
            ...current,
            {
              id: crypto.randomUUID(),
              kind: "error",
              text: "收到无法解析的流式数据片段。",
              timestamp: Date.now(),
            },
          ]);
        }
      };

      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const parts = buffer.split("\n\n");
        buffer = parts.pop() ?? "";

        for (const part of parts) {
          processEventBlock(part);
        }
      }

      if (buffer.trim()) {
        processEventBlock(buffer);
      }
    } catch (resumeError) {
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
      setIsSending(false);
    }
  }

  function applySsePayload(payload: Record<string, unknown>) {
    if (payload.error && typeof payload.error === "object") {
      const errorText = (payload.error as { message?: string }).message ?? "Unknown runtime error";
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "error",
          text: errorText,
          timestamp: Date.now(),
        },
      ]);
      return;
    }

    if (payload.object === "response") {
      const runId = extractRunId(payload);
      if (runId) {
        currentRunIdRef.current = runId;
      }

      const status = typeof payload.status === "string" ? payload.status : "unknown";
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: `run status: ${status}`,
          timestamp: Date.now(),
          runId,
        },
      ]);

      if (
        runId &&
        (status === "completed" || status === "failed" || status === "cancelled") &&
        currentRunIdRef.current === runId
      ) {
        currentRunIdRef.current = null;
      }
      return;
    }

    if (payload.object === "message") {
      const id = typeof payload.id === "string" ? payload.id : crypto.randomUUID();
      const role = typeof payload.role === "string" ? payload.role : "assistant";
      const status = typeof payload.status === "string" ? payload.status : undefined;
      const runId =
        extractRunId(payload) ??
        messageToRunIdRef.current[id] ??
        currentRunIdRef.current ??
        undefined;
      const text = extractTextFromContent(payload.content);
      const normalizedText = text.trim();
      const hitlEvent = parseHitlEvent(normalizedText);
      if (hitlEvent) {
        applyHitlEvent(hitlEvent);
        return;
      }

      if (role === "assistant") {
        latestAssistantMessageIdRef.current = id;
      }

      if (runId) {
        messageToRunIdRef.current[id] = runId;
        runToMessageIdRef.current[runId] = id;
        setActivities((current) => bindPendingToolsForRunToMessage(current, runId, id));
      }

      setMessages((current) => {
        const existing = current.find((message) => message.id === id);
        if (!existing) {
          if (role !== "user" && normalizedText.length === 0) {
            return current;
          }
          return [...current, { id, role, text, status, runId }];
        }

        const nextText = normalizedText.length > 0 && text.length >= existing.text.length ? text : existing.text;
        return current.map((message) =>
          message.id === id
            ? {
                ...message,
                role,
                status,
                text: nextText,
                runId: runId ?? message.runId,
              }
            : message
        );
      });
      return;
    }

    if (payload.object === "content" && payload.type === "text") {
      const msgId = typeof payload.msg_id === "string" ? payload.msg_id : null;
      const text = typeof payload.text === "string" ? payload.text : "";
      if (!msgId || !text) {
        return;
      }
      const hitlEvent = parseHitlEvent(text);
      if (hitlEvent) {
        applyHitlEvent(hitlEvent);
        return;
      }

      const runId =
        extractRunId(payload) ??
        messageToRunIdRef.current[msgId] ??
        currentRunIdRef.current ??
        undefined;

      latestAssistantMessageIdRef.current = msgId;
      if (runId) {
        messageToRunIdRef.current[msgId] = runId;
        runToMessageIdRef.current[runId] = msgId;
        setActivities((current) => bindPendingToolsForRunToMessage(current, runId, msgId));
      }

      setMessages((current) => {
        const existing = current.find((message) => message.id === msgId);
        if (!existing) {
          return [
            ...current,
            {
              id: msgId,
              role: "assistant",
              text,
              status: typeof payload.status === "string" ? payload.status : "in_progress",
              runId,
            },
          ];
        }

        return current.map((message) =>
          message.id === msgId
            ? {
                ...message,
                text: `${message.text}${text}`,
                status: typeof payload.status === "string" ? payload.status : message.status,
                runId: runId ?? message.runId,
              }
            : message
        );
      });
      return;
    }

    if (payload.object === "content" && payload.type === "data") {
      const data = payload.data as Record<string, unknown> | undefined;
      const runId = extractRunId(data) ?? extractRunId(payload) ?? currentRunIdRef.current ?? undefined;
      const mappedMessageId = runId ? runToMessageIdRef.current[runId] : undefined;

      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "tool",
          text: buildToolActivityText(data),
          timestamp: Date.now(),
          messageId: mappedMessageId,
          runId,
        },
      ]);
      return;
    }

    if (payload.object) {
      const objectName = typeof payload.object === "string" ? payload.object : "unknown";
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: `event: ${objectName}`,
          timestamp: Date.now(),
          runId: extractRunId(payload),
        },
      ]);
    }
  }

  function renderWorkspaceNode(node: WorkspaceNode, depth = 0): JSX.Element {
    if (node.type === "directory") {
      return (
        <details className="tree-node tree-directory" key={node.path} open={depth < 2}>
          <summary>
            <span className="tree-icon">D</span>
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

    return (
      <div className="tree-node tree-file" key={node.path}>
        <span className="tree-icon">F</span>
        <span className="tree-name">{node.name}</span>
        <span className="tree-path">{node.path}</span>
        <span className="tree-size">{typeof node.size === "number" ? formatBytes(node.size) : ""}</span>
      </div>
    );
  }

  const visibleMessages = messages.filter(hasRenderableMessageText);
  const visibleMessageIds = new Set(visibleMessages.map((message) => message.id));
  const pendingToolActivities = activities
    .filter(
      (item) =>
        item.kind === "tool" &&
        (!item.messageId || !visibleMessageIds.has(item.messageId))
    )
    .slice(-8);

  return (
    <main className="app-shell">
      <aside className="left-panel">
        <section className="panel-card hero-card">
          <div className="panel-label">Prototype Console</div>
          <h1>ImageToArkTS</h1>
          <p>上传草图和需求文件，然后直接和 deep agent 对话，生成 HarmonyOS 原型。</p>
        </section>

        <section className="panel-card">
          <div className="panel-label">User Input</div>
          <form className="upload-form" onSubmit={handleUpload}>
            <input
              id="file-input"
              type="file"
              ref={fileInputRef}
              onChange={handleFileInputChange}
              style={{ display: "none" }}
            />
            <button disabled={isUploading || showImageDescriptionDialog} type="submit">
              {isUploading ? "Uploading..." : selectedFiles && selectedFiles.length > 0 ? "上传文件" : "选择文件"}
            </button>
            {selectedFiles && selectedFiles.length > 0 ? (
              <p className="muted">已选择: {selectedFiles[0].name}</p>
            ) : null}
          </form>

          {showImageDescriptionDialog ? (
            <div className="image-desc-dialog">
              <div className="panel-label">Image Description</div>
              <p className="muted">检测到图片文件，请填写图片描述，帮助 agent 更准确理解上传素材。</p>
              {pendingImagePreviewUrl ? (
                <img
                  src={pendingImagePreviewUrl}
                  alt={pendingImageFile?.name ?? "pending upload preview"}
                  className="image-preview"
                />
              ) : null}
              {pendingImageFile ? <p className="file-path">待上传: {pendingImageFile.name}</p> : null}
              <textarea
                value={imageDescription}
                onChange={(event) => setImageDescription(event.target.value)}
                placeholder="例如：这是一张计算器主界面草图，上方是表达式显示区，下方是数字键盘。"
                rows={4}
              />
              <div className="dialog-actions">
                <button
                  className="secondary-button"
                  type="button"
                  onClick={() => {
                    if (pendingImagePreviewUrl) {
                      URL.revokeObjectURL(pendingImagePreviewUrl);
                    }
                    setPendingImageFile(null);
                    setPendingImagePreviewUrl("");
                    setSelectedFiles(null);
                    setShowImageDescriptionDialog(false);
                    setImageDescription("");
                    clearFileInputValue();
                  }}
                >
                  关闭
                </button>
                <button
                  type="button"
                  disabled={isUploading || !pendingImageFile || !imageDescription.trim()}
                  onClick={() => void handleConfirmImageUpload()}
                >
                  {isUploading ? "上传中..." : "确认上传"}
                </button>
              </div>
            </div>
          ) : null}

          <div className="file-list">
            {files.length === 0 ? <p className="muted">当前还没有上传文件。</p> : null}
            {files.map((file) => (
              <div className="file-item" key={file.path}>
                <div className="file-item-main">
                  <div className="file-name">{file.name}</div>
                  <div className="file-path">{file.path}</div>
                  {file.description ? <div className="file-path">描述: {file.description}</div> : null}
                </div>
                <div className="file-item-actions">
                  <span className="file-size">{formatBytes(file.size)}</span>
                  <button
                    className="file-delete-button"
                    type="button"
                    disabled={deletingFileName === file.name}
                    onClick={() => void handleDeleteFile(file.name)}
                  >
                    {deletingFileName === file.name ? "删除中..." : "删除"}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="panel-card">
          <div className="panel-row">
            <div className="panel-label">Agent Workspace</div>
            <button className="secondary-button" disabled={isResetting} type="button" onClick={handleReset}>
              {isResetting ? "Resetting..." : "Reset"}
            </button>
          </div>
          <p className="muted">像本地文件夹一样查看当前 `agent_workspace` 的目录结构。</p>
          <div className="workspace-tree">
            {workspaceTree ? renderWorkspaceNode(workspaceTree) : <p className="muted">正在加载目录结构...</p>}
          </div>
        </section>

      </aside>

      <section className="chat-panel">
        <header className="chat-header">
          <div className="session-header-main">
            <div className="panel-label">Conversation</div>
            <h2>{sessions.find((item) => item.id === sessionId)?.title ?? `Session ${sessionId.slice(0, 8)}`}</h2>
            <div className="session-controls">
              <select
                value={sessionId}
                onChange={(event) => handleSwitchSession(event.target.value)}
              >
                {sessions
                  .slice()
                  .sort((a, b) => b.updatedAt - a.updatedAt)
                  .map((item) => (
                    <option key={item.id} value={item.id}>
                      {item.title} · {item.id.slice(0, 8)}
                    </option>
                  ))}
              </select>
              <button className="secondary-button" type="button" onClick={handleCreateSession}>
                新建会话
              </button>
            </div>
          </div>
          <div className="header-chip">
            {isSending ? "Agent Running" : hitlPending ? "Waiting Human" : "Ready"}
          </div>
        </header>

        <div className="chat-scroll" ref={scrollRef}>
          {visibleMessages.length === 0 ? (
            <section className="empty-card">
              <h3>先上传资料，再开始对话</h3>
              <p>建议先把草图、截图、需求文档上传到左侧，再告诉 agent 你想做什么应用。</p>
            </section>
          ) : null}

          {visibleMessages.map((message) => (
            <div className={`message-row message-${message.role}`} key={message.id}>
              <article className="message-card">
                <div className="message-meta">
                  <span>{message.role === "user" ? "You" : "Agent"}</span>
                  <span>{message.status ?? "in_progress"}</span>
                </div>
                <div className="message-text">{message.text}</div>

                {message.role === "assistant" ? (
                  (() => {
                    const inlineTools = activities.filter(
                      (item) =>
                        item.kind === "tool" &&
                        (item.messageId === message.id ||
                          (!!message.runId && !item.messageId && item.runId === message.runId))
                    );
                    if (inlineTools.length === 0) {
                      return null;
                    }
                    return (
                      <details className="inline-tool-trace" open={message.status === "in_progress"}>
                        <summary>
                          执行过程 · {inlineTools.length} 条
                        </summary>
                        <div className="inline-tool-list">
                          {inlineTools.map((item) => (
                            <div className="inline-tool-item" key={item.id}>
                              <div>{item.text}</div>
                              <div className="activity-time">{new Date(item.timestamp).toLocaleTimeString()}</div>
                            </div>
                          ))}
                        </div>
                      </details>
                    );
                  })()
                ) : null}
              </article>
            </div>
          ))}

          {pendingToolActivities.length > 0 ? (
            <div className="message-row message-assistant" key="pending-assistant-thinking">
              <article className="message-card">
                <div className="message-meta">
                  <span>Agent</span>
                  <span>in_progress</span>
                </div>
                <div className="message-text muted">正在思考与调用工具...</div>
                <details className="inline-tool-trace" open>
                  <summary>执行过程 · {pendingToolActivities.length} 条</summary>
                  <div className="inline-tool-list">
                    {pendingToolActivities.map((item) => (
                      <div className="inline-tool-item" key={item.id}>
                        <div>{item.text}</div>
                        <div className="activity-time">{new Date(item.timestamp).toLocaleTimeString()}</div>
                      </div>
                    ))}
                  </div>
                </details>
              </article>
            </div>
          ) : null}
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
          <textarea
            rows={5}
            value={input}
            onChange={(event) => setInput(event.target.value)}
            placeholder="描述你想生成的 HarmonyOS 原型，比如：做一个带计算页和换算页的计算器应用。"
          />
          <div className="composer-footer">
            <div className="muted">{error ?? "聊天请求会直接发送到 /process"}</div>
            <button disabled={isSending || !input.trim()} type="submit">
              {isSending ? "Running..." : "Send"}
            </button>
          </div>
        </form>
      </section>
    </main>
  );
}
