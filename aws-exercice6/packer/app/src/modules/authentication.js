const PREFIX = 'secret-';

function isSecret(secret) {
  return secret.startsWith(PREFIX);
}

function isAuth(secret) {
  const validPassphrase = process.env.PASSPHRASE || 'mysecretphrase';
  const passphrase = secret.split(PREFIX)[1];

  return passphrase === validPassphrase;
}

function auth(secret) {
  if (secret) {
    if (isSecret(secret)) {
      if (isAuth(secret)) {
        return { status: 200, message: 'Success' };
      }
      return { status: 403, message: 'Forbidden.' };
    }
    return { status: 400, message: 'Bad request.' };
  }
  return { status: 401, message: 'No secret provided.' };
}

module.exports = auth;
