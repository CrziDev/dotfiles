# Wallpaper source

`mountains-gray.jpg` is derived from this Unsplash photo (snowy Himalayan peaks):

https://images.unsplash.com/photo-1454496522488-7a8e488e8606

License: Unsplash License (https://unsplash.com/license): free to use, modify and
redistribute, no attribution required.

Changes: cropped to 2560x1440, converted to grayscale, darkened slightly
(`ffmpeg -vf "crop=2560:1440:0:128,format=gray,eq=brightness=-0.20:contrast=1.08:gamma=0.85"`).

`mountains-dusk.jpg` (the one in use) is `mountains-gray.jpg` with the sky darkened toward the top, so
the transparent bar's white text reads over it (top 4% strip averages ~73/255 instead of ~163):

```sh
ffmpeg -i mountains-gray.jpg -vf "format=gray,geq=lum='st(0,min(1,Y/(H*0.45)));lum(X,Y)*(0.45+0.55*ld(0)*ld(0)*(3-2*ld(0)))'" -q:v 2 mountains-dusk.jpg
```
