const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#181818", /* black   */
  [1] = "#5F6C66", /* red     */
  [2] = "#757C74", /* green   */
  [3] = "#6A8279", /* yellow  */
  [4] = "#928475", /* blue    */
  [5] = "#3F8684", /* magenta */
  [6] = "#67928C", /* cyan    */
  [7] = "#c5c5c5", /* white   */

  /* 8 bright colors */
  [8]  = "#725d5d",  /* black   */
  [9]  = "#5F6C66",  /* red     */
  [10] = "#757C74", /* green   */
  [11] = "#6A8279", /* yellow  */
  [12] = "#928475", /* blue    */
  [13] = "#3F8684", /* magenta */
  [14] = "#67928C", /* cyan    */
  [15] = "#c5c5c5", /* white   */

  /* special colors */
  [256] = "#181818", /* background */
  [257] = "#c5c5c5", /* foreground */
  [258] = "#c5c5c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
