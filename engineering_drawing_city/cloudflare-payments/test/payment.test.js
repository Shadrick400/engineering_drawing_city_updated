import test from "node:test";
import assert from "node:assert/strict";
import worker, { normalizePhone, normalizeStatus } from "../src/index.js";

test("normalizes a Zambian local mobile number", () => {
  assert.equal(normalizePhone("0971234567"), "260971234567");
});

test("normalizes international Zambian number with plus and spaces", () => {
  assert.equal(normalizePhone("+260 971 234 567"), "260971234567");
});

test("rejects invalid phone numbers", () => {
  for (const value of ["", "12345", "097123456", "09712345678", "abc0971234567", "250971234567"]) {
    assert.throws(() => normalizePhone(value));
  }
});

test("maps provider success statuses", () => {
  for (const value of ["SUCCESSFUL", "success", "COMPLETED", "TS"]) {
    assert.equal(normalizeStatus(value), "successful");
  }
});

test("maps provider failure statuses", () => {
  for (const value of ["FAILED", "failure", "REJECTED", "DECLINED", "EXPIRED", "CANCELLED"]) {
    assert.equal(normalizeStatus(value), "failed");
  }
});

test("keeps unknown provider states pending", () => {
  for (const value of ["", "PENDING", "PROCESSING", "unknown"]) {
    assert.equal(normalizeStatus(value), "pending");
  }
});

test("OPTIONS returns CORS preflight without authentication", async () => {
  const response = await worker.fetch(new Request("https://worker.test/payments/initiate", { method: "OPTIONS" }), {});
  assert.equal(response.status, 204);
});

test("GET is rejected", async () => {
  const response = await worker.fetch(new Request("https://worker.test/payments/initiate", { method: "GET" }), {});
  assert.equal(response.status, 405);
});

test("payment endpoints require Firebase authentication", async () => {
  const response = await worker.fetch(new Request("https://worker.test/payments/initiate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ provider: "AIRTEL", phone: "0971234567", requestId: "edc_test_request_1234567890" }),
  }), {});
  assert.equal(response.status, 401);
});
