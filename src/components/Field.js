import React from 'react';
import SubField from './SubField';
import './Field.css';

export default function Field(props) {
  const listSubFieldsName = props.data.subFields.map(
    (e) =>
      e.skills.reduce(function (acc, skill) {
        return acc || skill.evaluation;
      }, 0) && (
        <div key={e.nameSubField} className="subfield">
          <h3 className="subfield-title">{e.nameSubField}</h3>
          <div className="flexbox">
            {e.skills.map(
              (skill) => skill.picture &&
                (
                <div className="child">
                  <img src={skill.picture} alt={skill.nameSkill}/>
                </div>
                )
            )}
          </div>
          <SubField data={e} />
        </div>
      )
  );

  return (
    <div>
      <div className="Field">{listSubFieldsName}</div>
    </div>
  );
}

//
// <img src={skill.picture} alt={skill.nameSkill} width="100" height="150" />
// 
