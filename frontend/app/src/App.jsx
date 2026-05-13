import { useEffect, useState } from "react";
import { listTodos, createTodo, updateTodo, deleteTodo } from "./api.js";

export default function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState(null);

  const reload = () =>
    listTodos()
      .then(setTodos)
      .catch((e) => setError(e.message));

  useEffect(() => {
    reload();
  }, []);

  const onAdd = async (e) => {
    e.preventDefault();
    const t = title.trim();
    if (!t) return;
    try {
      await createTodo(t);
      setTitle("");
      reload();
    } catch (e) {
      setError(e.message);
    }
  };

  const onToggle = async (todo) => {
    try {
      await updateTodo(todo.id, { done: !todo.done });
      reload();
    } catch (e) {
      setError(e.message);
    }
  };

  const onDelete = async (id) => {
    try {
      await deleteTodo(id);
      reload();
    } catch (e) {
      setError(e.message);
    }
  };

  return (
    <main
      style={{
        fontFamily: "system-ui, sans-serif",
        maxWidth: 480,
        margin: "2rem auto",
        padding: "0 1rem",
      }}
    >
      <h1>Todo</h1>
      {error && <p style={{ color: "crimson" }}>Error: {error}</p>}
      <form onSubmit={onAdd} style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="What needs doing?"
          style={{ flex: 1, padding: 8 }}
        />
        <button type="submit">Add</button>
      </form>
      <ul style={{ listStyle: "none", padding: 0 }}>
        {todos.map((t) => (
          <li
            key={t.id}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              padding: "6px 0",
            }}
          >
            <input
              type="checkbox"
              checked={t.done}
              onChange={() => onToggle(t)}
            />
            <span
              style={{
                flex: 1,
                textDecoration: t.done ? "line-through" : "none",
              }}
            >
              {t.title}
            </span>
            <button onClick={() => onDelete(t.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </main>
  );
}
