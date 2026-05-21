const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#121212", /* black   */
  [1] = "#6A6D73", /* red     */
  [2] = "#797C83", /* green   */
  [3] = "#817F84", /* yellow  */
  [4] = "#7D8288", /* blue    */
  [5] = "#909499", /* magenta */
  [6] = "#999EA2", /* cyan    */
  [7] = "#c3c3c3", /* white   */

  /* 8 bright colors */
  [8]  = "#6e5959",  /* black   */
  [9]  = "#6A6D73",  /* red     */
  [10] = "#797C83", /* green   */
  [11] = "#817F84", /* yellow  */
  [12] = "#7D8288", /* blue    */
  [13] = "#909499", /* magenta */
  [14] = "#999EA2", /* cyan    */
  [15] = "#c3c3c3", /* white   */

  /* special colors */
  [256] = "#121212", /* background */
  [257] = "#c3c3c3", /* foreground */
  [258] = "#c3c3c3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
