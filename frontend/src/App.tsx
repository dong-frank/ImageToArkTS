import { useEffect, useRef, useState } from "react";

type ChatMessage = {
  id: string;
  role: string;
  text: string;
  status?: string;
};

type UploadedFile = {
  name: string;
  path: string;
  size: number;
  content_type?: string;
};

type ActivityItem = {
  id: string;
  kind: "tool" | "status" | "error";
  text: string;
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

export default function App() {
  const [sessionId] = useState(() => crypto.randomUUID());
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [input, setInput] = useState("");
  const [selectedFiles, setSelectedFiles] = useState<FileList | null>(null);
  const [clearExisting, setClearExisting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    void refreshFiles();
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

      const response = await fetch(`${API_BASE}/user-input/upload`, {
        method: "POST",
        body: formData,
      });
      if (!response.ok) {
        throw new Error(`Upload failed: ${response.status}`);
      }

      await refreshFiles();
      setSelectedFiles(null);
      setClearExisting(false);
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: "已上传新的用户输入文件。",
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

      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const parts = buffer.split("\n\n");
        buffer = parts.pop() ?? "";

        for (const part of parts) {
          const dataLine = part
            .split("\n")
            .find((line) => line.startsWith("data: "));
          if (!dataLine) {
            continue;
          }

          const payload = JSON.parse(dataLine.slice(6)) as Record<string, unknown>;
          applySsePayload(payload);
        }
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
        },
      ]);
      return;
    }

    if (payload.object === "response") {
      const status = typeof payload.status === "string" ? payload.status : "unknown";
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "status",
          text: `run status: ${status}`,
        },
      ]);
      return;
    }

    if (payload.object === "message") {
      const id = typeof payload.id === "string" ? payload.id : crypto.randomUUID();
      const role = typeof payload.role === "string" ? payload.role : "assistant";
      const status = typeof payload.status === "string" ? payload.status : undefined;
      const content = Array.isArray(payload.content) ? payload.content : [];
      const text = content
        .map((item) => {
          if (item && typeof item === "object" && "text" in item) {
            const value = (item as { text?: unknown }).text;
            return typeof value === "string" ? value : "";
          }
          return "";
        })
        .join("");

      setMessages((current) => {
        const existing = current.find((message) => message.id === id);
        if (!existing) {
          return [...current, { id, role, text, status }];
        }
        return current.map((message) =>
          message.id === id
            ? {
                ...message,
                role,
                status,
                text: text || message.text,
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
            },
          ];
        }

        return current.map((message) =>
          message.id === msgId
            ? {
                ...message,
                text: `${message.text}${text}`,
                status: typeof payload.status === "string" ? payload.status : message.status,
              }
            : message
        );
      });
      return;
    }

    if (payload.object === "content" && payload.type === "data") {
      const data = payload.data as Record<string, unknown> | undefined;
      const toolName = typeof data?.name === "string" ? data.name : "tool";
      setActivities((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          kind: "tool",
          text: `tool call: ${toolName}`,
        },
      ]);
    }
  }

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
              onChange={(event) => setSelectedFiles(event.target.files)}
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
          <div className="file-list">
            {files.length === 0 ? <p className="muted">当前还没有上传文件。</p> : null}
            {files.map((file) => (
              <div className="file-item" key={file.path}>
                <div>
                  <div className="file-name">{file.name}</div>
                  <div className="file-path">{file.path}</div>
                </div>
                <span className="file-size">{formatBytes(file.size)}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="panel-card">
          <div className="panel-label">Activity</div>
          <div className="activity-list">
            {activities.length === 0 ? <p className="muted">这里会显示运行状态和工具调用。</p> : null}
            {activities.map((item) => (
              <div className={`activity-item activity-${item.kind}`} key={item.id}>
                {item.text}
              </div>
            ))}
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
          {messages.length === 0 ? (
            <section className="empty-card">
              <h3>先上传资料，再开始对话</h3>
              <p>建议先把草图、截图、需求文档上传到左侧，再告诉 agent 你想做什么应用。</p>
            </section>
          ) : null}

          {messages.map((message) => (
            <div className={`message-row message-${message.role}`} key={message.id}>
              <article className="message-card">
                <div className="message-meta">
                  <span>{message.role === "user" ? "You" : "Agent"}</span>
                  <span>{message.status ?? "in_progress"}</span>
                </div>
                <div className="message-text">{message.text || "..."}</div>
              </article>
            </div>
          ))}
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
