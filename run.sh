jekyll build --incremental
echo "============>jekyll build"

cp -r /e/note/image /e/note/myblog/_site/
echo "============>xcopy"

cd _site
echo "============>cd _site"

git add .
echo "============>git add"

git commit -m "update"
echo "============>git commit"

git push -u origin "master"
echo "============>git push"


