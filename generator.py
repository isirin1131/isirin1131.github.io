from pathlib import Path

files_and_dirs = Path("./")

ret = files_and_dirs.glob("[[][0-9][0-9][0-9][]]*")

header0 = '''
<!DOCTYPE html>

<html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
'''

header1 = '''
</title>
    </head>

    <body> <div class="container">
'''

end = '''
    </div> </body>
    
</html>

<style>
    .container {
        height: 100%;
        width: 100%;
        
    }

    .myhref {
        color: darkorange;
        font-family: consolas;
        font-size: large;
        font-weight: lighter;
    }
    
    div {
        border-style: groove;
        border-width: 1px;
        border-color: yellow;
    }
    html {
        background-color: black;
    }
</style>
'''

maintmp = '''
        <h1 style="color: aliceblue; width: 100%; font-family: 'Courier New', Courier, monospace;">
            zhecai's blog
        </h1>
        <p style="color: aliceblue; width: 100%; font-family:'Courier New', Courier, monospace; width: 100%; font-size: large;">
        email: 13793971886@139.com <br>
        qq: 3632915050 <br>
        wechat: telzert
        </p>

        <p style="color: wheat; font-size:small;">
            本网站为个人博客，<br>
            分享个人文章，题材多样。<br>
            所有文章仅代表个人观点。
        </p>

        <pre>
            #set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

            #show math.equation: set text(font: "Neo Euler")
            </pre>
        <hr />
'''

# 此循环生成子页面的 html，并将其链接到 index.html 中
for ite in ret :
    tmp = '''
<h1 style="color: aliceblue; width: 100%; font-family: 'Courier New', Courier, monospace;">
'''
    tmp = tmp + ite.name[5:] + "</h1>\n"
    sub = Path("./" + ite.name)
    for subite in sub.iterdir() :
        tmp += ('<a href="../' + ite.name + "/" + subite.name + '" class="myhref" target="_blank">' + subite.stem + '</a><br>\n')

    with open("./object/" + ite.name + ".html", mode="w", encoding="utf-8") as f :
        f.write(header0 + ite.name[5:] + header1 + tmp + end)
    
    maintmp = maintmp + '<a href="./object/' + ite.name + '''.html" style="color: yellowgreen; font-weight: lighter; font-size: x-large; width: 100%; font-family: 'Courier New', Courier, monospace;" target="_blank">''' + ite.name[5:] + '</a><br>\n'

    
    
with open("./index.html", mode="w", encoding="utf-8") as f :
    f.write(header0 + "zhecai's blog" + header1 + maintmp + end)
