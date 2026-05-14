async function request(path, options = {}) {
  const res = await fetch(`/api${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  if (!res.ok) throw new Error(`API ${res.status}`);
  if (res.status === 204) return null;
  return res.json();
}

export const listTodos = () => request("/todos");
export const createTodo = (title) =>
  request("/todos", { method: "POST", body: JSON.stringify({ title }) });
export const updateTodo = (id, patch) =>
  request(`/todos/${id}`, { method: "PATCH", body: JSON.stringify(patch) });
export const deleteTodo = (id) =>
  request(`/todos/${id}`, { method: "DELETE" });
