import React from 'react';
import DATA from '../Helpers/data_keylan_copie_js';
import './Bulletin.css';
import Field from './Field';

let a = -1;
let b = -1;
let c = -1;

let newData = {
  fields: []
};

DATA.forEach(e => {
  if (e.nameField) {
    a++;
    b = -1;
    newData.fields[a] = {
      nameField: e.nameField,
      subFields: []
    };
  }
  if (e.nameSubField) {
    b++;
    c = 0;
    newData.fields[a].subFields[b] = {
      nameSubField: e.nameSubField,
      skills: []
    };
  }
  newData.fields[a].subFields[b].skills[c] = {
    nameSkill: e.nameSkill,
    level: e.level,
    date: e.date,
    evaluation: e.evaluation,
    picture: e.picture
  };
  c++;
})

console.log('newData');
console.log(newData);

export default function Bulletin() {
  
  const listFieldsName = newData.fields.map((d) => (
    <div key={d.nameField} className="field">
      <h2 className="field-title display-6 ">{d.nameField}</h2>
      <Field data={d} />
    </div>
  ));

  return (
    <div className="bulletin">
      <div className="header bloc-titre">
        <h1 className="display-5 font-weight-bold">
          Carnet de suivi des apprentissages <br /> à l'école maternelle
        </h1>
        <h3 className="h5">-</h3>
        <h2 className="h3">{newData?.student}</h2>
        <h3 className="h5">-</h3>
        <div className="header-info">
          <h3>Classe de : {newData?.classe} </h3>
          <h3>Niveau : {newData?.classeLevel} </h3>
          <h3>Année scolaire : 2020 - 2021</h3>
          <h3>Bilan de Mars</h3>
        </div>
      </div>

      <div className="Body">{listFieldsName}</div>

      <div className="footer">
        <h3 className="title-footer">Bilan pédagogique</h3>
        <div className="teacherComment">
          <br />
        </div>
      </div>
    </div>
  );
}
