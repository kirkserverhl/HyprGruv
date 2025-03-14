# lolcolor
Turn anything into a color!

## Install

If you are using `lolcolor` in javascript code, a simple install will add it to your dependencies.

```bash
npm install lolcolor
```

If this is getting bundled into front-end javascript, you might want to install into your devDependencies instead.

```bash
npm install -D lolcolor

```

If requiring easy use via command-line, install globally. 

```bash
npm install -g lolcolor
```

If not running often, consider using `npx` instead of a global install.

```bash
npx lolcolor "Hey now, you're an all star"
```

## Usage

### Command Line

`lolcolor` can be used from the command line.

```bash
lolcolor "get your game on, go play"
```

### Function

The simplest way to use `lolcolor` in code is as a simple function.

```javascript

const lolcolor = require('lolcolor');

const text = 'Hey now, you\'re a rock star';

console.log(lolcolor(text));

```

### ColorBuilder

If you need a bit more control over your colors you can use the ColorBuilder.

```javascript

const { ColorBuilder } = require('lolcolor');

const builderText = 'get the show on, get paid';

const colorBuilder = new ColorBuilder();

const [colorR, colorG, colorB] = colorBuilder.fromString(builderText).asRgb().butOnly64Colors().create();

console.log(`Red value:${colorR}, Green value:${colorG}, Blue value:${colorB}`);

```

| Category    | Method           | Parameters     | Description                        |
| ----------- | ---------------- | -------------- | ---------------------------------- |
| Begin       | fromString       | source<string> | The input text                     |
| Create      | create           | (none)         | Output your color                  |
| Color mode  | asHex            | (none)         | Use hex color mode                 |
| Color mode  | asHsl            | (none)         | Use HSL color mode                 |
| Color mode  | asRgb            | (none)         | Use RGB color mode                 |
| Color limit | butOnly8Colors   | (none)         | Only choose from 8 colors          |
| Color limit | butOnly64Colors  | (none)         | Only choose from 64 colors (6-bit) |
| Color limit | butOnly256Colors | (none)         | Only choose from 256 colors        |
