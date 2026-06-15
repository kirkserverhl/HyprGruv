const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0f1223", /* black   */
  [1] = "#7B859E", /* red     */
  [2] = "#8B93AD", /* green   */
  [3] = "#DBAAAF", /* yellow  */
  [4] = "#8B9FC1", /* blue    */
  [5] = "#8EAED6", /* magenta */
  [6] = "#8FBCE5", /* cyan    */
  [7] = "#c3c3c8", /* white   */

  /* 8 bright colors */
  [8]  = "#5e6074",  /* black   */
  [9]  = "#7B859E",  /* red     */
  [10] = "#8B93AD", /* green   */
  [11] = "#DBAAAF", /* yellow  */
  [12] = "#8B9FC1", /* blue    */
  [13] = "#8EAED6", /* magenta */
  [14] = "#8FBCE5", /* cyan    */
  [15] = "#c3c3c8", /* white   */

  /* special colors */
  [256] = "#0f1223", /* background */
  [257] = "#c3c3c8", /* foreground */
  [258] = "#c3c3c8",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
