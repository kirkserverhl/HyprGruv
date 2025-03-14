'use strict';

module.exports = function splitStringIntoChunks(str, chunkCount) {
  const chunkSize = Math.floor(str.length / chunkCount);
  const chunks = [];

  for (let i = 0; i < chunkCount; i++) {
    const start = i * chunkSize;

    if (i < chunkCount - 1) {
      chunks.push(str.substring(start, start + chunkSize))
    } else {
      // Get everything that's left
      chunks.push(str.substring(start));
    }
  }

  return chunks;
};
