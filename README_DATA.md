# Data Helpers/data.js
  http://www.convertcsv.com/csv-to-json.htm

Fields: [
    {
      NameField: 'MOBILISER LE LANGAGE DANS TOUTES SES DIMENSIONS',
      CommentField: 'Encouragent',
      SubFields: [
        {
          NameSubField: "L'oral : Oser entrer en communication",
          Skills: [
            {
              nameSkill: 'Je communique avec des gestes.  ',
              date: '01/01/21',
              evaluation: 'Bien',
              picture: '',
            },
            {
              nameSkill: 'AAB',
              date: '',
              evaluation: '',
              picture: '',
            },
          ],
        },
        {
          NameSubField: 'AB',
          Skills: [
            {
              nameSkill: 'ABA',
              date: '01/01/21',
              evaluation: 'Bien',
              picture: '',
            },
            {
              nameSkill: 'ABB',
              date: '01/01/21',
              evaluation: 'Bien',
              picture: '',
            },
          ],
        },
      ],
    },
    {
      NameField: 'B',
      CommentField: 'Encouragent',

Convert CSV in JSON

{
  field: 'A',
  subField: 'AA',
  nameSkill: 'AAA',
  level: 'GS',
  date: '01/01/21',
  evaluation: 'Bien',
  picture: '',
},

- if field empty
  delete

- if subField empty
  delete

# subField
- before
{
  NameSubField: 'BB',
  Skills: [

- after
 ],
    },

# field
- before
{"NameField": "$1","CommentField": "","SubFields": [

- after
],},

# done
- find & replace
"field": "",

***
"subField": "",

***
"field": "(.*)",\n
],\n},\n{\n"NameField": "$1",\n"CommentField": "",\n"SubFields": [\n{
***
"subField": "(.*)",\n
],\n},\n{\n"nameSubField": "$1",\n"Skills": [\n{\n
***
- picture regex:
picture: (\d+)
picture: '../Media/simon/(\d+).jpeg'


# List student
enzo,
eva,
fariha,
kellycia,
kelyan,
keylan,
khaina,
lirije,
malak,
marion,
matt,
nayan,
nina,
rachid,
rania,
sawda,
simon,
sofiane,
warren,
wesley,
