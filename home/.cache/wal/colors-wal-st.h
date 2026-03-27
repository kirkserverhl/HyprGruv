const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0f0f0e", /* black   */
  [1] = "#C8AE36", /* red     */
  [2] = "#8D8A76", /* green   */
  [3] = "#788486", /* yellow  */
  [4] = "#8F9187", /* blue    */
  [5] = "#ADAD95", /* magenta */
  [6] = "#AEAF99", /* cyan    */
  [7] = "#c3c3c2", /* white   */

  /* 8 bright colors */
  [8]  = "#6c6c58",  /* black   */
  [9]  = "#C8AE36",  /* red     */
  [10] = "#8D8A76", /* green   */
  [11] = "#788486", /* yellow  */
  [12] = "#8F9187", /* blue    */
  [13] = "#ADAD95", /* magenta */
  [14] = "#AEAF99", /* cyan    */
  [15] = "#c3c3c2", /* white   */

  /* special colors */
  [256] = "#0f0f0e", /* background */
  [257] = "#c3c3c2", /* foreground */
  [258] = "#c3c3c2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
