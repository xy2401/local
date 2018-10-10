## https://stackoverflow.com/questions/26126362/converting-all-files-in-a-folder-to-md-using-pandoc-on-mac
find ./ -iname "*.md" -type f -exec sh -c 'pandoc "${0}"  -s  --from markdown --to html5 -o "${0%.md}.html"' {} \;
