import React from 'react';
import dayjs from 'dayjs';
import 'dayjs/locale/fr';
import './Date.css'

export default function Date(dateData) {

  return (
    <p className="validation">{`Validée en ${dateData}`}</p>
  )

  // debugger;
  // let date = dayjs(props.dateData, 'MMM-YY').locale('fr');
  // return (
  //     <p className="validation">{`Validée en ${dayjs(date).locale('fr').format('MMMM YYYY')}`}</p>
  // );
}

// <p className="skill">{props.dateData ? `Validée en ${Dayjs(date).format('MMMM YYYY')}` : 'Validée'}</p>