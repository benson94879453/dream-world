import { spawn } from 'node:child_process';

const serverPath = String.raw`C:\Users\user\AppData\Roaming\npm\node_modules\godot-mcp-server\dist\index.js`;

function encodeMessage(message) {
  const body = Buffer.from(JSON.stringify(message), 'utf8');
  return Buffer.concat([
    Buffer.from(`Content-Length: ${body.length}\r\n\r\n`, 'utf8'),
    body,
  ]);
}

async function main() {
  const child = spawn('node', [serverPath], { stdio: ['pipe', 'pipe', 'pipe'] });

  let stdout = Buffer.alloc(0);
  let stderr = '';

  child.stderr.on('data', (chunk) => {
    stderr += chunk.toString();
  });

  child.stdout.on('data', (chunk) => {
    stdout = Buffer.concat([stdout, chunk]);
  });

  function tryParseMessages() {
    const messages = [];

    while (true) {
      const headerEnd = stdout.indexOf('\r\n\r\n');
      if (headerEnd === -1) {
        break;
      }

      const headerText = stdout.slice(0, headerEnd).toString('utf8');
      const match = headerText.match(/Content-Length: (\d+)/i);
      if (!match) {
        throw new Error(`Missing Content-Length header: ${headerText}`);
      }

      const contentLength = Number(match[1]);
      const messageStart = headerEnd + 4;
      const messageEnd = messageStart + contentLength;
      if (stdout.length < messageEnd) {
        break;
      }

      const jsonText = stdout.slice(messageStart, messageEnd).toString('utf8');
      stdout = stdout.slice(messageEnd);
      messages.push(JSON.parse(jsonText));
    }

    return messages;
  }

  function waitForMessage(predicate, timeoutMs = 10000) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        cleanup();
        reject(new Error(`Timed out waiting for message. stderr:\n${stderr}`));
      }, timeoutMs);

      const onData = () => {
        try {
          const messages = tryParseMessages();
          for (const message of messages) {
            if (predicate(message)) {
              cleanup();
              resolve(message);
              return;
            }
          }
        } catch (error) {
          cleanup();
          reject(error);
        }
      };

      const cleanup = () => {
        clearTimeout(timer);
        child.stdout.off('data', onData);
      };

      child.stdout.on('data', onData);
      onData();
    });
  }

  child.stdin.write(
    encodeMessage({
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: { name: 'opencode-mcp-test', version: '1.0.0' },
      },
    }),
  );

  const initializeResponse = await waitForMessage((message) => message.id === 1);

  child.stdin.write(
    encodeMessage({
      jsonrpc: '2.0',
      method: 'notifications/initialized',
      params: {},
    }),
  );

  child.stdin.write(
    encodeMessage({
      jsonrpc: '2.0',
      id: 2,
      method: 'tools/call',
      params: {
        name: 'get_godot_status',
        arguments: {},
      },
    }),
  );

  const statusResponse = await waitForMessage((message) => message.id === 2);

  console.log(
    JSON.stringify(
      {
        initializeResponse,
        statusResponse,
        stderr,
      },
      null,
      2,
    ),
  );

  child.kill('SIGTERM');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
