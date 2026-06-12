const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1a0b0b", /* black   */
  [1] = "#384367", /* red     */
  [2] = "#4A4F50", /* green   */
  [3] = "#62696C", /* yellow  */
  [4] = "#6A6F8E", /* blue    */
  [5] = "#817D9A", /* magenta */
  [6] = "#78868C", /* cyan    */
  [7] = "#c5c2c2", /* white   */

  /* 8 bright colors */
  [8]  = "#6f5a5a",  /* black   */
  [9]  = "#384367",  /* red     */
  [10] = "#4A4F50", /* green   */
  [11] = "#62696C", /* yellow  */
  [12] = "#6A6F8E", /* blue    */
  [13] = "#817D9A", /* magenta */
  [14] = "#78868C", /* cyan    */
  [15] = "#c5c2c2", /* white   */

  /* special colors */
  [256] = "#1a0b0b", /* background */
  [257] = "#c5c2c2", /* foreground */
  [258] = "#c5c2c2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
