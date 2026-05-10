import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    target: 'es2023',
    sourcemap: true,
    minify: 'esbuild',
  },
  server: {
    port: 5173,
    strictPort: true,
  },
  test: {
    globals: false,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
  },
});
