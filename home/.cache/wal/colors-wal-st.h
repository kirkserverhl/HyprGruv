const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101213", /* black   */
  [1] = "#D58A75", /* red     */
  [2] = "#749190", /* green   */
  [3] = "#7B9E95", /* yellow  */
  [4] = "#879893", /* blue    */
  [5] = "#8CA799", /* magenta */
  [6] = "#AEA098", /* cyan    */
  [7] = "#c3c3c4", /* white   */

  /* 8 bright colors */
  [8]  = "#59636e",  /* black   */
  [9]  = "#D58A75",  /* red     */
  [10] = "#749190", /* green   */
  [11] = "#7B9E95", /* yellow  */
  [12] = "#879893", /* blue    */
  [13] = "#8CA799", /* magenta */
  [14] = "#AEA098", /* cyan    */
  [15] = "#c3c3c4", /* white   */

  /* special colors */
  [256] = "#101213", /* background */
  [257] = "#c3c3c4", /* foreground */
  [258] = "#c3c3c4",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
