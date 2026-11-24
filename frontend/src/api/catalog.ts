import type { Catalog, Category, Product } from "./types";

export type ProductInput = {
  sku: string;
  barcode: string | null;
  name: string;
  description: string | null;
  categoryId: number;
  brandId: number | null;
  unitId: number | null;
  costPrice: number;
  sellingPrice: number;
  taxRate: number;
};

export type CategoryInput = { name: string; description: string | null };

export type ProductQuery = {
  keyword: string;
  categoryId: string;
  active: string;
};

export class ApiError extends Error {
  readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(path, {
    ...init,
    headers: {
      Accept: "application/json",
      ...(init.body ? { "Content-Type": "application/json" } : {}),
      ...init.headers,
    },
  });

  if (!response.ok) {
    let message = `${path} returned ${response.status} ${response.statusText}`;
    try {
      const body = await response.json() as { message?: string; errors?: Record<string, string> };
      const fieldErrors = body.errors ? Object.values(body.errors).join(" ") : "";
      message = [body.message, fieldErrors].filter(Boolean).join(": ") || message;
    } catch {
      // Some framework errors are not JSON; keep the HTTP status as a useful fallback.
    }
    throw new ApiError(message, response.status);
  }

  if (response.status === 204 || response.headers.get("content-length") === "0") {
    return undefined as T;
  }
  const text = await response.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

const productPath = "/api/v1/products";
const categoryPath = "/api/v1/categories";

export async function fetchCatalog(signal?: AbortSignal): Promise<Catalog> {
  const [products, categories] = await Promise.all([
    request<Product[]>(productPath, { signal }),
    request<Category[]>(categoryPath, { signal }),
  ]);
  return { products, categories };
}

export function fetchHealth(signal?: AbortSignal) {
  return request<{ status: string; message: string }>("/api/v1/health", { signal });
}

export function getProduct(id: number | string) {
  return request<Product>(`${productPath}/${encodeURIComponent(id)}`);
}

export function getCategory(id: number | string) {
  return request<Category>(`${categoryPath}/${encodeURIComponent(id)}`);
}

export function createProduct(input: ProductInput) {
  return request<Product>(productPath, { method: "POST", body: JSON.stringify(input) });
}

export function updateProduct(id: number | string, input: ProductInput) {
  return request<Product>(`${productPath}/${encodeURIComponent(id)}`, { method: "PUT", body: JSON.stringify(input) });
}

export function deleteProduct(id: number | string) {
  return request<void>(`${productPath}/${encodeURIComponent(id)}`, { method: "DELETE" });
}

export function setProductActive(id: number | string, active: boolean) {
  const action = active ? "activate" : "deactivate";
  return request<Product>(`${productPath}/${encodeURIComponent(id)}/${action}`, { method: "PUT" });
}

export function createCategory(input: CategoryInput) {
  return request<Category>(categoryPath, { method: "POST", body: JSON.stringify(input) });
}

export function updateCategory(id: number | string, input: CategoryInput) {
  return request<Category>(`${categoryPath}/${encodeURIComponent(id)}`, { method: "PUT", body: JSON.stringify(input) });
}

export function deleteCategory(id: number | string) {
  return request<void>(`${categoryPath}/${encodeURIComponent(id)}`, { method: "DELETE" });
}

async function getProductsByQuery(query: ProductQuery): Promise<Product[]> {
  const requests: Promise<Product[]>[] = [];

  if (query.keyword.trim()) {
    const params = new URLSearchParams({ keyword: query.keyword.trim() });
    requests.push(request<Product[]>(`${productPath}/search?${params.toString()}`));
  }
  if (query.categoryId !== "all" && query.categoryId !== "uncategorized") {
    requests.push(request<Product[]>(`${productPath}/category/${encodeURIComponent(query.categoryId)}`));
  }
  if (query.active !== "all") {
    const params = new URLSearchParams({ active: String(query.active === "active") });
    requests.push(request<Product[]>(`${productPath}/active?${params.toString()}`));
  }
  if (query.categoryId === "uncategorized") requests.push(request<Product[]>(productPath));

  if (!requests.length) return request<Product[]>(productPath);
  const resultSets = await Promise.all(requests);
  const byId = new Map(resultSets[0].map((product) => [String(product.id), product]));
  for (const resultSet of resultSets.slice(1)) {
    const ids = new Set(resultSet.map((product) => String(product.id)));
    for (const id of byId.keys()) if (!ids.has(id)) byId.delete(id);
  }
  const products = [...byId.values()];
  return query.categoryId === "uncategorized"
    ? products.filter((product) => product.categoryId == null)
    : products;
}

export { getProductsByQuery };
