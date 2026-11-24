export type Product = {
  id: number | string;
  sku: string;
  barcode?: string | null;
  name: string;
  description?: string | null;
  categoryId?: number | string | null;
  brandId?: number | string | null;
  unitId?: number | string | null;
  costPrice?: number | string | null;
  sellingPrice: number | string;
  taxRate?: number | string | null;
  active: boolean;
  createdAt?: string | null;
};

export type Category = {
  id: number | string;
  name: string;
  description?: string | null;
  active: boolean;
};

export type Catalog = {
  products: Product[];
  categories: Category[];
};
