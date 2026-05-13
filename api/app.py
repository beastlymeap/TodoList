import os
import threading
from flask import Flask, jsonify, request, abort

app = Flask(__name__)

_lock = threading.Lock()
_todos: dict[int, dict] = {}
_next_id = 1


def _serialize(todo: dict) -> dict:
    return {"id": todo["id"], "title": todo["title"], "done": todo["done"]}


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api/todos")
def list_todos():
    with _lock:
        return jsonify([_serialize(t) for t in _todos.values()])


@app.post("/api/todos")
def create_todo():
    global _next_id
    data = request.get_json(silent=True) or {}
    title = (data.get("title") or "").strip()
    if not title:
        abort(400, description="title is required")
    with _lock:
        todo = {"id": _next_id, "title": title, "done": False}
        _todos[_next_id] = todo
        _next_id += 1
    return jsonify(_serialize(todo)), 201


@app.patch("/api/todos/<int:todo_id>")
def update_todo(todo_id: int):
    data = request.get_json(silent=True) or {}
    with _lock:
        todo = _todos.get(todo_id)
        if todo is None:
            abort(404)
        if "title" in data:
            title = (data.get("title") or "").strip()
            if not title:
                abort(400, description="title cannot be empty")
            todo["title"] = title
        if "done" in data:
            todo["done"] = bool(data["done"])
        return jsonify(_serialize(todo))


@app.delete("/api/todos/<int:todo_id>")
def delete_todo(todo_id: int):
    with _lock:
        if _todos.pop(todo_id, None) is None:
            abort(404)
    return "", 204


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)), debug=True)
