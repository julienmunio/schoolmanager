import React from 'react';
import Date from './Date';
import './SubField.css';

export default function SubField(props) {
  // console.log(`DEBUG SubFields.js Data.subFields : `);
  // console.log(props.data);

  const listSubFieldsName = props.data.skills.map(
    (skillData) =>
      skillData.evaluation && (
        <>
          <li className="competence" key={skillData.nameSkill}>
            {skillData.nameSkill}
            <span>{skillData.evaluation !== 'oui' ? skillData.evaluation : ''}</span>
          </li>
            <p className="validation">{`Validée en ${skillData.date}`}</p>
        </>
      )
  );

  return <ul className="row" >{listSubFieldsName}</ul>;
}