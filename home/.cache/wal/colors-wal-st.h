const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0d2010", /* black   */
  [1] = "#B79171", /* red     */
  [2] = "#40778B", /* green   */
  [3] = "#767F80", /* yellow  */
  [4] = "#2CAAB1", /* blue    */
  [5] = "#669495", /* magenta */
  [6] = "#98A1A0", /* cyan    */
  [7] = "#c2c7c3", /* white   */

  /* 8 bright colors */
  [8]  = "#5d7160",  /* black   */
  [9]  = "#B79171",  /* red     */
  [10] = "#40778B", /* green   */
  [11] = "#767F80", /* yellow  */
  [12] = "#2CAAB1", /* blue    */
  [13] = "#669495", /* magenta */
  [14] = "#98A1A0", /* cyan    */
  [15] = "#c2c7c3", /* white   */

  /* special colors */
  [256] = "#0d2010", /* background */
  [257] = "#c2c7c3", /* foreground */
  [258] = "#c2c7c3",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
