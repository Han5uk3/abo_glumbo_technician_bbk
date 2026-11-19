"use strict";

// Minimal in-memory Firestore covering what the OTP code uses. Transactions
// buffer their writes and discard them on throw, like the real thing.

function clone(value) {
  if (value === undefined) return undefined;
  return JSON.parse(JSON.stringify(value));
}

function getPath(data, path) {
  return path.split(".").reduce((value, key) => (value == null ? undefined : value[key]), data);
}

function applyUpdate(target, update) {
  for (const [path, value] of Object.entries(update)) {
    const keys = path.split(".");
    let cursor = target;
    for (const key of keys.slice(0, -1)) {
      cursor[key] = cursor[key] ?? {};
      cursor = cursor[key];
    }
    cursor[keys[keys.length - 1]] = clone(value);
  }
}

function snapshot(ref, data) {
  return {
    id: ref.id,
    ref,
    exists: data !== undefined,
    data: () => clone(data),
  };
}

class FakeFirestore {
  constructor() {
    this.store = new Map();
  }

  key(collection, id) {
    return `${collection}/${id}`;
  }

  seed(collection, id, data) {
    this.store.set(this.key(collection, id), clone(data));
  }

  read(collection, id) {
    return clone(this.store.get(this.key(collection, id)));
  }

  write(ref, operation, data, options) {
    const key = this.key(ref.collection, ref.id);
    if (operation === "delete") {
      this.store.delete(key);
      return;
    }
    if (operation === "set" && !options?.merge) {
      this.store.set(key, clone(data));
      return;
    }
    const current = this.store.get(key);
    if (operation === "update" && current === undefined) {
      throw new Error(`No document to update: ${key}`);
    }
    const next = current ?? {};
    applyUpdate(next, data);
    this.store.set(key, next);
  }

  collection(name) {
    return new FakeQuery(this, name, []);
  }

  batch() {
    const writes = [];
    return {
      update: (ref, data) => writes.push([ref, "update", data]),
      set: (ref, data, options) => writes.push([ref, "set", data, options]),
      commit: async () => {
        for (const [ref, operation, data, options] of writes) {
          this.write(ref, operation, data, options);
        }
      },
    };
  }

  async runTransaction(fn) {
    const writes = [];
    const tx = {
      get: (ref) => ref.get(),
      set: (ref, data, options) => writes.push([ref, "set", data, options]),
      update: (ref, data) => writes.push([ref, "update", data]),
      delete: (ref) => writes.push([ref, "delete"]),
    };
    const result = await fn(tx);
    for (const [ref, operation, data, options] of writes) {
      this.write(ref, operation, data, options);
    }
    return result;
  }
}

class FakeQuery {
  constructor(db, collection, filters, max) {
    this.db = db;
    this.name = collection;
    this.filters = filters;
    this.max = max;
  }

  doc(id) {
    const db = this.db;
    const ref = {
      id,
      collection: this.name,
      get: async () => snapshot(ref, db.store.get(db.key(this.name, id))),
      set: async (data, options) => db.write(ref, "set", data, options),
      update: async (data) => db.write(ref, "update", data),
      delete: async () => db.write(ref, "delete"),
    };
    return ref;
  }

  where(field, _operator, value) {
    return new FakeQuery(this.db, this.name, [...this.filters, [field, value]], this.max);
  }

  limit(max) {
    return new FakeQuery(this.db, this.name, this.filters, max);
  }

  async get() {
    const prefix = `${this.name}/`;
    const docs = [];
    for (const [key, data] of this.db.store) {
      if (!key.startsWith(prefix)) continue;
      if (this.filters.every(([field, value]) => getPath(data, field) === value)) {
        docs.push(snapshot(this.doc(key.slice(prefix.length)), data));
      }
    }
    const limited = this.max === undefined ? docs : docs.slice(0, this.max);
    return { docs: limited, empty: limited.length === 0, size: limited.length };
  }
}

module.exports = { FakeFirestore };
