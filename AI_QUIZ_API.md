# AI Quiz 持久化 API 接口文档

## 概述

前端在生成 AI quiz 内容后，会自动调用后端 API 进行持久化保存。页面加载时也会自动尝试加载已保存的内容。

## API 接口

### 1. 保存 Quiz 内容

**接口地址**: `POST /api/v1/assistant/chat/save`

**请求头**:
```
Content-Type: application/json
Accept: application/json
```

**请求体**:
```json
{
  "content": "生成的 quiz 内容（Markdown 格式，包含 {{< quiz >}} shortcodes）",
  "metadata": {
    "difficulty": "中等",
    "count": "3",
    "timestamp": "2025-01-15T10:30:00.000Z",
    "pageUrl": "http://example.com/编程语言/编程语言-AI在线测试",
    "pageTitle": "JAVA在线测试"
  }
}
```

**响应**:
```json
{
  "success": true,
  "message": "保存成功",
  "data": {
    "id": "保存的唯一标识符",
    "savedAt": "2025-01-15T10:30:00.000Z"
  }
}
```

**错误响应**:
```json
{
  "success": false,
  "message": "错误信息"
}
```

### 2. 加载已保存的 Quiz 内容

**接口地址**: `GET /api/v1/assistant/chat/load?pageUrl={当前页面URL}`

**请求头**:
```
Accept: application/json
```

**查询参数**:
- `pageUrl`: 当前页面的完整 URL（用于标识保存的内容属于哪个页面）

**响应**:
```json
{
  "success": true,
  "message": "加载成功",
  "data": {
    "content": "保存的 quiz 内容（Markdown 格式）",
    "metadata": {
      "difficulty": "中等",
      "count": "3",
      "timestamp": "2025-01-15T10:30:00.000Z",
      "pageUrl": "http://example.com/编程语言/编程语言-AI在线测试",
      "pageTitle": "JAVA在线测试"
    },
    "savedAt": "2025-01-15T10:30:00.000Z"
  }
}
```

**未找到内容时**:
```json
{
  "success": false,
  "message": "未找到已保存的内容",
  "code": "NOT_FOUND"
}
```
HTTP 状态码: `404`

## 存储建议

### 方案 1: 文件系统存储
- 按页面 URL 的哈希值或路径创建文件
- 存储路径: `data/quiz/{pageHash}.json` 或 `data/quiz/{pagePath}.json`
- 文件内容包含完整的请求体和元数据

### 方案 2: 数据库存储
- 表结构建议:
  ```sql
  CREATE TABLE ai_quiz_content (
    id VARCHAR(64) PRIMARY KEY,
    page_url VARCHAR(512) NOT NULL,
    page_title VARCHAR(256),
    content TEXT NOT NULL,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_page_url (page_url)
  );
  ```

### 方案 3: 内存缓存 + 持久化
- 使用 Redis 等缓存系统
- 定期持久化到数据库或文件系统

## 实现示例

### Spring Boot 示例

```java
@RestController
@RequestMapping("/api/v1/assistant/chat")
public class QuizPersistenceController {

    @PostMapping("/save")
    public ResponseEntity<ApiResponse> saveQuiz(@RequestBody QuizSaveRequest request) {
        // 保存逻辑
        String pageUrl = request.getMetadata().getPageUrl();
        String content = request.getContent();
        
        // 保存到数据库或文件系统
        String id = saveToDatabase(pageUrl, content, request.getMetadata());
        
        return ResponseEntity.ok(ApiResponse.success(
            Map.of("id", id, "savedAt", Instant.now().toString())
        ));
    }

    @GetMapping("/load")
    public ResponseEntity<ApiResponse> loadQuiz(@RequestParam String pageUrl) {
        // 加载逻辑
        QuizContent content = loadFromDatabase(pageUrl);
        
        if (content == null) {
            return ResponseEntity.status(404).body(
                ApiResponse.error("未找到已保存的内容", "NOT_FOUND")
            );
        }
        
        return ResponseEntity.ok(ApiResponse.success(content));
    }
}
```

## 注意事项

1. **URL 规范化**: 保存和加载时，需要对 `pageUrl` 进行规范化处理（去除查询参数、锚点等）
2. **内容验证**: 保存前验证内容格式是否正确
3. **大小限制**: 建议限制单个保存内容的大小（如 1MB）
4. **过期策略**: 可以考虑实现内容过期机制（如 30 天后自动删除）
5. **版本控制**: 可以考虑保存多个版本，允许用户查看历史版本

## 前端行为

- **自动保存**: 生成成功后自动调用保存接口（静默失败，不影响用户体验）
- **自动加载**: 页面加载时自动尝试加载已保存内容（静默失败，不影响用户体验）
- **覆盖策略**: 同一页面的新内容会覆盖旧内容（如果需要保留历史，后端需要实现版本控制）

