# Useful commands

# Trim video
ffmpeg -accurate_seek -ss 00:00:07.5 -i source.mp4 -c:v copy -c:a copy out.mp4

# Overlay 2 images with transparency
convert bottom.png \( top.png -alpha set -channel a -evaluate set 75% +channel \) -gravity center -compose over -composite out.png
composite -dissolve 75 -gravity Center top.png bottom.png -alpha Set out.png

# Merge frames into video (muted)
ffmpeg -framerate 25 -i frames/%04d.png -c:v libx264 -crf 7 -pix_fmt yuv420p -y muted.mp4

# Copy sound from another video
ffmpeg -i muted.mp4 -i original.mp4 -c:v copy -map 0:v:0 -map 1:a:0 -y out.mp4

# Convert all JPGs to PNG & Remove
for f in *.jpg; do convert "$f" -quality 100 -format png "${f/.jpg/.png}" && rm "$f"; done

# Resize images
for f in *.png; do convert "$f" -quality 100 -filter Lanczos -resize 1080x1350 "${f/.png/-lg.png}"; done