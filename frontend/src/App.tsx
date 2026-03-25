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

export default function App() {
  const [sessionId] = useState(() => crypto.randomUUID());
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [workspaceTree, setWorkspaceTree] = useState<WorkspaceNode | null>(null);
  const [input, setInput] = useState("");
  const [selectedFiles, setSelectedFiles] = useState<FileList | null>(null);
  const [imageDescription, setImageDescription] = useState("");
  const [showImageDescriptionDialog, setShowImageDescriptionDialog] = useState(false);
  const [clearExisting, setClearExisting] = useState(false);
  const [deletingFileName, setDeletingFileName] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [isResetting, setIsResetting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const latestAssistantMessageIdRef = useRef<string | null>(null);
  const currentRunIdRef = useRef<string | null>(null);
  const runToMessageIdRef = useRef<Record<string, string>>({});
  const messageToRunIdRef = useRef<Record<string, string>>({});

  useEffect(() => {
    void refreshFiles();
    void refreshWorkspaceTree();
  }, []);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages, activities]);

  async function refreshFiles() {
    const response = await fetch(`${API_BASE}/user-input/files`);
    if (!response.ok) {
      throw new Error(`Failed to list files: ${response.status}`);
    }
    const data = (await response.json()) as { files: UploadedFile[] };
    setFiles(data.files ?? []);
  }

  async function refreshWorkspaceTree() {
    const response = await fetch(`${API_BASE}/workspace/tree`);
    if (!response.ok) {
      throw new Error(`Failed to load workspace tree: ${response.status}`);
    }
    const data = (await response.json()) as { root?: WorkspaceNode };
    setWorkspaceTree(data.root ?? null);
  }

  async function handleUpload(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedFiles || selectedFiles.length === 0 || isUploading) {
      return;
    }

    setIsUploading(true);
    setError(null);
    try {
      const formData = new FormData();
      for (const file of Array.from(selectedFiles)) {
        formData.append("files", file);
      }
      formData.append("clear_existing", String(clearExisting));
      if (hasImageFile(selectedFiles) && imageDescription.trim()) {
        formData.append("image_description", imageDescription.trim());
      }

      const response = await fetch(`${API_BASE}/user-input/upload`, {
        method: "POST",
        body: formData,
      });
      if (!response.ok) {
        throw new Error(`Upload failed: ${response.status}`);
      }

      await refreshFiles();
      await refreshWorkspaceTree();
      setSelectedFiles(null);
      setImageDescription("");
      setShowImageDescriptionDialog(false);
      setClearExisting(false);
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
      const fileInput = document.getElementById("file-input") as HTMLInputElement | null;
      if (fileInput) {
        fileInput.value = "";
      }
    }
  }

  function handleFileInputChange(event: React.ChangeEvent<HTMLInputElement>) {
    const nextFiles = event.target.files;
    setSelectedFiles(nextFiles);

    if (hasImageFile(nextFiles)) {
      setShowImageDescriptionDialog(true);
      return;
    }

    setShowImageDescriptionDialog(false);
    setImageDescription("");
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
        `${API_BASE}/user-input/files/${encodeURIComponent(fileName)}`,
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
    setInput("");
    setError(null);
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
              multiple
              type="file"
              onChange={handleFileInputChange}
            />
            <label className="checkbox-row">
              <input
                checked={clearExisting}
                type="checkbox"
                onChange={(event) => setClearExisting(event.target.checked)}
              />
              上传前清空旧文件
            </label>
            <button disabled={isUploading || !selectedFiles || selectedFiles.length === 0} type="submit">
              {isUploading ? "Uploading..." : "Upload Files"}
            </button>
          </form>

          {showImageDescriptionDialog ? (
            <div className="image-desc-dialog">
              <div className="panel-label">Image Description</div>
              <p className="muted">检测到图片文件，请填写图片描述，帮助 agent 更准确理解上传素材。</p>
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
                  onClick={() => setShowImageDescriptionDialog(false)}
                >
                  关闭
                </button>
                <span className="muted">上传时将随文件一起发送该描述</span>
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
          <div>
            <div className="panel-label">Conversation</div>
            <h2>Session {sessionId.slice(0, 8)}</h2>
          </div>
          <div className="header-chip">{isSending ? "Agent Running" : "Ready"}</div>
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
