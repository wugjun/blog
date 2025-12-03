---
title: "DeepSeek"
date: 2025-12-03
description: "通过 DeepSeek 模型进行流式对话的在线工具"
lead: "实时查看 AI 助手的流式响应"
disable_comments: true
authorbox: true
toc: false
categories:
  - "工具效率"
tags:
  - "AI"
  - "DeepSeek"
menu: main
---

<div class="deepseek-chat-page">
  <h1>DeepSeek 智能助手</h1>
  <div id="chat-container"></div>
  <div id="input-container">
    <input type="text" id="message-input" placeholder="输入您的问题..." />
    <button id="send-btn">发送</button>
  </div>
</div>

<style>
.deepseek-chat-page {
  font-family: Arial, sans-serif;
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

#chat-container {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  height: 400px;
  overflow-y: auto;
}

.message {
  margin-bottom: 10px;
  padding: 10px;
  border-radius: 5px;
}

.user-message {
  background-color: #e3f2fd;
  text-align: right;
}

.ai-message {
  background-color: #f5f5f5;
}

.streaming {
  border-left: 3px solid #4CAF50;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.5; }
  100% { opacity: 1; }
}

#input-container {
  display: flex;
  gap: 10px;
}

#message-input {
  flex: 1;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

#send-btn {
  padding: 10px 20px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
}

#send-btn:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.typing-indicator {
  color: #666;
  font-style: italic;
}
</style>

<script>
(function() {
  const chatContainer = document.getElementById('chat-container');
  const messageInput = document.getElementById('message-input');
  const sendBtn = document.getElementById('send-btn');
  const endpoint = 'http://localhost:18080/api/v1/assistant/chat/stream';
  let currentController = null;

  function addUserMessage(content) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message user-message';
    messageDiv.innerHTML = `<strong>您:</strong> ${content}`;
    chatContainer.appendChild(messageDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
  }

  function createAiMessage() {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message ai-message streaming';
    messageDiv.innerHTML = '<strong>AI:</strong> <span class="streaming-content"></span><span class="typing-indicator">▋</span>';
    chatContainer.appendChild(messageDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
    return messageDiv;
  }

  async function sendMessage() {
    const message = messageInput.value.trim();
    if (!message) return;

    messageInput.disabled = true;
    sendBtn.disabled = true;

    addUserMessage(message);
    messageInput.value = '';

    const aiMessageDiv = createAiMessage();
    const streamingContent = aiMessageDiv.querySelector('.streaming-content');

    if (currentController) {
      currentController.abort();
    }

    const requestData = {
      model: "deepseek-chat",
      messages: [{ role: "user", content: message }],
      temperature: 0.7,
      max_tokens: 2000,
      stream: true
    };

    try {
      currentController = new AbortController();
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream'
        },
        body: JSON.stringify(requestData),
        signal: currentController.signal
      });

      if (!response.ok || !response.body) {
        throw new Error('服务返回异常状态：' + response.status);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      let fullResponse = '';
      let doneStreaming = false;

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (let rawLine of lines) {
          let line = rawLine.trim();
          if (!line) continue;

          if (line.startsWith('data:')) {
            const payload = line.slice(5).trim();
            if (payload === '[DONE]') {
              doneStreaming = true;
              break;
            }
            fullResponse += payload;
            streamingContent.textContent = fullResponse;
            chatContainer.scrollTop = chatContainer.scrollHeight;
          }
          // 忽略 id: / event: 等控制字段
        }

        if (doneStreaming) break;
      }

      finalizeMessage(aiMessageDiv);
    } catch (error) {
      if (error.name === 'AbortError') {
        streamingContent.textContent += ' (已中断)';
      } else {
        console.error('请求错误:', error);
        streamingContent.textContent = '请求失败: ' + error.message;
      }
      finalizeMessage(aiMessageDiv);
    } finally {
      currentController = null;
    }
  }

  function finalizeMessage(aiMessageDiv) {
    aiMessageDiv.classList.remove('streaming');
    const indicator = aiMessageDiv.querySelector('.typing-indicator');
    if (indicator) indicator.style.display = 'none';
    enableInput();
  }

  function enableInput() {
    messageInput.disabled = false;
    sendBtn.disabled = false;
    messageInput.focus();
  }

  messageInput.addEventListener('keypress', (event) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  });

  sendBtn.addEventListener('click', sendMessage);
  window.addEventListener('load', () => messageInput.focus());
})();
</script>

