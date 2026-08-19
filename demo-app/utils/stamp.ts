export function stamp(message: string): string {
  return `${new Date().toLocaleTimeString()}  ${message}`;
}
