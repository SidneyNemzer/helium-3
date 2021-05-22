export type WorkerOptions = {
  id: string;
};

/**
 * Data sent from worker threads to the main process. The main process forwards
 * the events to the clients over websockets. The message usually has more
 * fields (see docs/protocol.md) but the main process only inspects the `type`.
 */
export type WorkerMessageOut = [
  { type: string }, // message
  number[] // player ids, recipients
];

/**
 * Messages sent from the main thread to workers. See `WorkerMessageOut`.
 */
export type WorkerMessageIn = { type: string };
