const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#160909", /* black   */
  [1] = "#4D4D4D", /* red     */
  [2] = "#605F60", /* green   */
  [3] = "#6E6E6E", /* yellow  */
  [4] = "#8E8E8E", /* blue    */
  [5] = "#A09FA0", /* magenta */
  [6] = "#AEAEAE", /* cyan    */
  [7] = "#c4c1c1", /* white   */

  /* 8 bright colors */
  [8]  = "#6c5959",  /* black   */
  [9]  = "#4D4D4D",  /* red     */
  [10] = "#605F60", /* green   */
  [11] = "#6E6E6E", /* yellow  */
  [12] = "#8E8E8E", /* blue    */
  [13] = "#A09FA0", /* magenta */
  [14] = "#AEAEAE", /* cyan    */
  [15] = "#c4c1c1", /* white   */

  /* special colors */
  [256] = "#160909", /* background */
  [257] = "#c4c1c1", /* foreground */
  [258] = "#c4c1c1",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
