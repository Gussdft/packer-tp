import { describe, expect, test } from 'vitest';
import auth from './authentication';

describe('auth module', () => {
  test('No secret should fail', () => {
    const response = auth();

    expect(response.status).toBe(401);
    expect(response.message).toBe('No secret provided.');
  });
  test('Bad secret should fail', () => {
    const response = auth('test');

    expect(response.status).toBe(400);
    expect(response.message).toBe('Bad request.');
  });
  test('Bad passphrase should fail', () => {
    const response = auth('secret-test');

    expect(response.status).toBe(403);
    expect(response.message).toBe('Forbidden.');
  });
  test('Correct passphrase should succeed', () => {
    const response = auth('secret-mysecretphrase');

    expect(response.status).toBe(200);
    expect(response.message).toBe('Success');
  });
});
