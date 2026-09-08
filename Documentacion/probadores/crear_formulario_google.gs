/**
 * Crea el formulario diario de CraftQuestAI (14 días).
 *
 * Uso:
 * 1. https://script.google.com → Nuevo proyecto
 * 2. Pega este archivo
 * 3. Ejecuta crearFormularioCraftQuest
 * 4. Autoriza tu cuenta de Google
 * 5. Ver → Registros de ejecución: copia "Responder" (link para testers)
 */
function crearFormularioCraftQuest() {
  const form = FormApp.create('CraftQuestAI — Diario de prueba (14 días)');

  form.setDescription(
    'Diario de CraftQuestAI (14 días).\n\n' +
      'Cada día, DESPUÉS de usar la app, envía este formulario una vez (~2 minutos).\n\n' +
      'App: https://app.craftquestai.com\n' +
      '• Día 1: crea cuenta, verifica el email, recorre Inicio y Perfil.\n' +
      '• No hace falta pagar. Si ves planes o Preparación+, solo explora.\n' +
      '• Si algo falla: cuéntalo (y adjunta captura si puedes).\n\n' +
      'Misiones: 1 Inicio/Perfil · 2 Crear quiz y practicar · 3 Editar e historial · ' +
      '4 Imagen o Excel · 5 Compartir código · 6 Invitado · 7 IA con PDF · ' +
      '8 Preparación+ · 9 Idioma/notificaciones · 10 Offline · 11 Estudiante · ' +
      '12 Docente · 13 Límites/contraseña · 14 Úsala a tu manera y cierra.'
  );

  form.setCollectEmail(true);
  form.setProgressBar(true);
  form.setLimitOneResponsePerUser(false);
  form.setShowLinkToRespondAgain(true);
  form.setConfirmationMessage(
    'Listo. Mañana: abre la app, haz la misión del día y vuelve a enviar este mismo formulario. Gracias.'
  );

  const dias = [];
  for (let i = 1; i <= 14; i++) {
    dias.push('Día ' + i);
  }

  form.addSectionHeaderItem().setTitle('Quién eres');

  form.addTextItem().setTitle('Tu nombre').setRequired(true);

  form
    .addTextItem()
    .setTitle('Email con el que te registraste en la app')
    .setRequired(true);

  form
    .addListItem()
    .setTitle('¿Qué día de la prueba es hoy?')
    .setChoiceValues(dias)
    .setRequired(true);

  form
    .addCheckboxItem()
    .setTitle('¿En qué usaste la app hoy?')
    .setChoiceValues([
      'Celular Android',
      'iPhone',
      'Computadora (Chrome / Safari / Edge)',
      'Tablet',
      'App instalada (Play / TestFlight)',
      'Navegador',
    ])
    .setRequired(true);

  form.addTextItem().setTitle('País o ciudad (aprox.)');

  form.addSectionHeaderItem().setTitle('Tu sesión de hoy');

  form
    .addMultipleChoiceItem()
    .setTitle('¿Cuánto tiempo usaste la app hoy?')
    .setChoiceValues([
      'Menos de 5 min',
      '5–15 min',
      '15–30 min',
      'Más de 30 min',
      'Hoy no pude entrar',
    ])
    .setRequired(true);

  form
    .addMultipleChoiceItem()
    .setTitle('¿Completaste la misión del día?')
    .setChoiceValues([
      'Sí, completa',
      'A medias',
      'No la hice',
      'No aplica / no entendí la misión',
    ])
    .setRequired(true);

  form
    .addScaleItem()
    .setTitle('Facilidad de lo que intentaste hoy')
    .setBounds(1, 5)
    .setLabels('Imposible o muy confuso', 'Claro y fluido')
    .setRequired(true);

  form
    .addMultipleChoiceItem()
    .setTitle('¿La app hizo lo que esperabas?')
    .setChoiceValues(['Sí', 'Más o menos', 'No', 'No llegué a usarla'])
    .setRequired(true);

  form.addParagraphTextItem().setTitle('Lo que funcionó bien hoy');
  form.addParagraphTextItem().setTitle('Lo que confundió, molestó o faltó');

  form
    .addMultipleChoiceItem()
    .setTitle('¿Encontraste un error o algo roto?')
    .setChoiceValues([
      'No',
      'Sí, molesto pero pude seguir',
      'Sí, no pude continuar',
    ])
    .setRequired(true);

  form
    .addParagraphTextItem()
    .setTitle('Si hubo error: qué ibas a hacer, qué pasó, texto del mensaje');

  form
    .addSectionHeaderItem()
    .setTitle('Solo día 1')
    .setHelpText('Si no es tu día 1, déjalo en blanco.');

  form
    .addParagraphTextItem()
    .setTitle('(Solo día 1) ¿Cómo estudias o enseñas hoy, sin esta app?');

  form
    .addCheckboxItem()
    .setTitle('(Solo día 1) ¿Eres…?')
    .setChoiceValues([
      'Estudiante',
      'Docente',
      'Me preparo un examen',
      'Creo material para otros',
      'Solo estoy ayudando a probar',
    ]);

  form
    .addSectionHeaderItem()
    .setTitle('Solo día 14 — cierre')
    .setHelpText('Si no es tu día 14, déjalo en blanco.');

  form
    .addScaleItem()
    .setTitle(
      '(Solo día 14) Del 0 al 10, ¿qué tanto recomendarías CraftQuestAI a un amigo que estudia o enseña?'
    )
    .setBounds(0, 10)
    .setLabels('Nada', 'Totalmente');

  form
    .addMultipleChoiceItem()
    .setTitle('(Solo día 14) ¿La usarías después de estos 14 días?')
    .setChoiceValues([
      'Sí, seguido',
      'Sí, de vez en cuando',
      'Solo si es gratis',
      'No',
    ]);

  form
    .addMultipleChoiceItem()
    .setTitle(
      '(Solo día 14) ¿Pagarías Pro (~5 USD/mes) o Teacher (~10 USD/mes) si te sirviera?'
    )
    .setChoiceValues([
      'Sí Pro',
      'Sí Teacher',
      'Solo si baja el precio',
      'No, con Free me basta',
      'No la usaría ni gratis',
    ]);

  form.addParagraphTextItem().setTitle('(Solo día 14) Lo más valioso de la app');
  form.addParagraphTextItem().setTitle('(Solo día 14) Lo primero que arreglarías');
  form.addParagraphTextItem().setTitle('Comentario libre');

  const url = form.getPublishedUrl();
  const edit = form.getEditUrl();
  Logger.log('Responder (link para testers): ' + url);
  Logger.log('Editar: ' + edit);
  return { url: url, edit: edit };
}
