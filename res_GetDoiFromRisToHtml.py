#===================================================================
# Extract doi links, titles and authors of literatures from "*.ris"
# as a list in format "*.html".
#===================================================================

import glob
import rispy
import pandas as pd

dirPathPattern = r"C:\Users\*\Desktop\*.ris"
result = glob.glob(dirPathPattern)
num=0
htmlfile=[]
print("start!")
for risFile in result:
    #print(risFile)
    with open(risFile,'r',encoding="utf-8") as bibliography_file:
        entries = rispy.load(bibliography_file)
        print(entries[0])
        for entry in entries:
            try:
                title=entry['primary_title']
            except:
                title=entry['title']
            au=entry['authors']
            au=str(au[0])
            au=au[:au.index(',')]
            try:
                year=entry['year']
            except:
                year=""
            try:
                abst=entry['abstract']
                num=num+1    
                print('<br>'+str(num)+'<br>')
                htmlfile.append('<br>'+str(num)+'<br>')
                print(au+year+"\n"+'<br>'+title+'<br>')
                htmlfile.append(au+year+"\n"+'<br>'+title+'<br>')
                try:
                    doi_site='https://www.doi.org/'+ entry['doi']
                    print('<a href='+doi_site+'>'+doi_site+'</a>'+'\n'+'<br>')
                    htmlfile.append('<a href='+doi_site+'>'+doi_site+'</a>'+'\n'+'<br>')
                except:
                    print("no doi"+'<br>')
                    htmlfile.append("no doi"+'<br>')
            except:
                abst=' '
                num=num+1
                print('<br>'+str(num)+'<br>')
                htmlfile.append('<br>'+str(num)+'<br>')
                print(au+year+"\n"+'<br>'+title+'<br>')
                htmlfile.append(au+year+"\n"+'<br>'+title+'<br>')
                try:
                    print('no abst'+'\n'+'<br>')
                    htmlfile.append('no abst'+'\n'+'<br>')
                    doi_site='https://www.doi.org/'+ entry['doi']
                    print('<a href='+doi_site+'>'+doi_site+'</a>'+'\n'+'<br>')
                    htmlfile.append('<a href='+doi_site+'>'+doi_site+'</a>'+'\n'+'<br>')
                except:
                    print("no doi"+'\n'+'<br>')
                    htmlfile.append("no doi"+'\n'+'<br>')

f=open(r"C:\Users\*\Desktop\*.txt", 'w',encoding="utf-8")
f.writelines(htmlfile)
f.close()