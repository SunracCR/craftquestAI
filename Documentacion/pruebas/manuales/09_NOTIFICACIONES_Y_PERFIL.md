# Pruebas manuales — Notificaciones y perfil

**Tiempo total:** 30–45 min

---

## M-NOT-01 — Registrar dispositivo para push (Android)

**Tiempo:** ~5 min · **Requisito:** FCM configurado en backend

### Pasos

1. Instala app en **Android** físico (push no funciona bien en emulador).
2. Inicia sesión.
3. Acepta permisos de **notificaciones** si el sistema lo pide.

### Deberías ver
- [ ] Permiso concedido (Ajustes → App → Notificaciones activas)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-NOT-02 — Recibir notificación push

**Tiempo:** ~15 min · **Requisito:** completar M-WH-04 (grace period) u otra acción que dispare notificación

### Pasos

1. Provoca un evento que genere notificación (ej. webhook grace period, o recordatorio de tarea próxima a vencer).
2. Pon la app en **segundo plano** o ciérrala.
3. Espera notificación en la **bandeja del sistema**.

### Deberías ver
- [ ] Push recibido con texto legible
- [ ] Al tocar, abre la app en pantalla relevante

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## M-NOT-03 — Bandeja in-app

**Tiempo:** ~8 min

### Pasos

1. En **Home**, toca icono de **campana** / notificaciones.
2. Revisa lista de notificaciones.
3. Toca una notificación para marcarla leída (o usa marcar todas).
4. Verifica que el **contador** de no leídas baja.

### Deberías ver
- [ ] Lista carga correctamente
- [ ] Contador unread coherente

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-NOT-04 — Preferencias de notificación

**Tiempo:** ~8 min

### Pasos

1. En notificaciones, abre **Preferencias** / settings.
2. Desactiva **email** para un tipo (ej. recordatorios).
3. Guarda.
4. Cierra app y vuelve a abrir preferencias.

### Deberías ver
- [ ] Cambios **persistidos**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PROF-01 — Editar perfil

**Tiempo:** ~8 min

### Pasos

1. Ve a **Perfil**.
2. Cambia **nombre para mostrar** a `QA Updated Name`.
3. Guarda si hace falta.
4. Cierra y abre app.

### Deberías ver
- [ ] Nombre actualizado en Perfil y Home

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-PROF-02 — Historial de pagos

**Tiempo:** ~5 min · **Cuenta:** con al menos una compra (M-PAY-02/03)

### Pasos

1. Perfil → **Historial de pagos**.
2. Revisa listado.

### Deberías ver
- [ ] Compra de suscripción listada con fecha

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## M-PROF-03 — Eliminar cuenta (opcional, cuenta desechable)

**Tiempo:** ~10 min · **Usa cuenta QA dedicada**

### Pasos

1. Perfil → **Eliminar cuenta**.
2. Confirma (escribe email o contraseña si lo pide).
3. Verifica logout.
4. Intenta **login** de nuevo con esa cuenta.

### Deberías ver
- [ ] Cuenta eliminada / login rechazado
- [ ] Datos no accesibles

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## Checklist — Notificaciones y perfil

| ID | Prueba | Resultado |
|----|--------|-----------|
| M-NOT-01 | Permiso push | ☐ |
| M-NOT-02 | Push recibido | ☐ |
| M-NOT-03 | Bandeja in-app | ☐ |
| M-NOT-04 | Preferencias | ☐ |
| M-PROF-01 | Editar perfil | ☐ |
| M-PROF-02 | Historial pagos | ☐ |
| M-PROF-03 | Eliminar cuenta | ☐ |

**Siguiente:** [10_FLUJOS_COMPLETOS.md](10_FLUJOS_COMPLETOS.md)
