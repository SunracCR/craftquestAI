# Pruebas manuales — Registro y login

**Plataformas:** Android, iOS, Web  
**Tiempo total estimado:** 45–60 min  
**App:** CraftQuest (no uses Postman salvo que se indique)

---

## M-AUTH-01 — Registro con email y verificación

**Prioridad:** P0 · **Tiempo:** ~10 min

### Antes de empezar
- [ ] Tienes un email **nuevo** que nunca usaste en CraftQuest
- [ ] Puedes abrir ese buzón (o ver logs de email en dev)

### Pasos

1. Abre la app CraftQuest.
2. En la pantalla de login, toca **Registrarse** / **Crear cuenta**.
3. Completa:
   - Email: `qa+nuevo-YYYYMMDD@tudominio.com`
   - Contraseña: `TestPass123!`
   - Nombre para mostrar: `QA Tester`
4. Envía el formulario.
5. Deberías llegar a una pantalla de **“Verifica tu email”** o similar.
6. Abre el email de CraftQuest (revisa spam).
7. Haz clic en el enlace de verificación **o** copia el código si la app lo pide.
8. Vuelve a la app y completa la verificación si hace falta.
9. Inicia sesión con el mismo email y contraseña.

### Deberías ver
- [ ] Tras registrarte: mensaje de verificación pendiente (no entras aún al home)
- [ ] Tras verificar: login exitoso
- [ ] Pantalla principal (Home) con tu nombre
- [ ] En **Perfil**: plan **Free** (o equivalente)

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A |
|------------|---------|-------|
| Fecha: | Dispositivo: | Notas: |

---

## M-AUTH-02 — Login con credenciales incorrectas

**Prioridad:** P0 · **Tiempo:** ~3 min

### Pasos

1. Cierra sesión (Perfil → Cerrar sesión).
2. En login, escribe un email válido pero **contraseña incorrecta**.
3. Intenta entrar.

### Deberías ver
- [ ] Error claro (no entras a la app)
- [ ] No se revela si el email existe o no (mensaje genérico)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AUTH-03 — Recuperar contraseña

**Prioridad:** P0 · **Tiempo:** ~10 min

### Antes de empezar
- [ ] Cuenta **ya verificada** (usa la de M-AUTH-01 o qa+free@...)

### Pasos

1. En login, toca **¿Olvidaste tu contraseña?**
2. Introduce el email de la cuenta.
3. Envía la solicitud.
4. Abre el email de reset.
5. Sigue el enlace (app o web según el enlace).
6. Establece una **nueva contraseña** (ej. `NewTest456!`).
7. Inicia sesión con la nueva contraseña.

### Deberías ver
- [ ] Email recibido en 1–2 minutos
- [ ] Contraseña cambiada correctamente
- [ ] Login con la contraseña **antigua** falla
- [ ] Login con la **nueva** funciona

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AUTH-04 — Login con Google

**Prioridad:** P0 · **Tiempo:** ~5 min  
**Plataforma:** Android, iOS o Web (prueba al menos una)

### Pasos

1. Cierra sesión si estás dentro.
2. En login, toca **Continuar con Google**.
3. Elige una cuenta Google de prueba.
4. Acepta permisos si Google los pide.
5. Espera a que la app cargue.

### Deberías ver
- [ ] Entras sin error
- [ ] Home visible
- [ ] Perfil muestra email de Google (o el asociado)

### Resultado

| ☐ Aprobado | ☐ Falló | Plataforma probada: | Notas: |

---

## M-AUTH-05 — Login con Apple (solo iOS / macOS / Web)

**Prioridad:** P1 · **Tiempo:** ~5 min

### Pasos

1. Cierra sesión.
2. Toca **Continuar con Apple**.
3. Completa el flujo de Apple ID (cuenta sandbox si aplica).

### Deberías ver
- [ ] Sesión iniciada correctamente

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## M-AUTH-06 — Cerrar sesión y volver a entrar

**Prioridad:** P1 · **Tiempo:** ~3 min

### Pasos

1. Estando logueado, ve a **Perfil**.
2. Toca **Cerrar sesión**.
3. Confirma si la app lo pide.
4. Vuelve a iniciar sesión con email/contraseña.

### Deberías ver
- [ ] Tras logout: pantalla de login
- [ ] Re-login funciona sin re-verificar email

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-AUTH-07 — Cambiar idioma de la app

**Prioridad:** P2 · **Tiempo:** ~3 min

### Pasos

1. Ve a **Perfil**.
2. Cambia idioma a **English**.
3. Navega a Home y login (logout/login si hace falta ver textos).
4. Repite con **Português** si está disponible.

### Deberías ver
- [ ] Textos de la UI cambian (no strings en inglés mezclados en español)
- [ ] Preferencia persiste al cerrar y abrir la app

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Checklist de sesión — Registro y login

| ID | Prueba | Resultado |
|----|--------|-----------|
| M-AUTH-01 | Registro + verificación | ☐ |
| M-AUTH-02 | Login incorrecto | ☐ |
| M-AUTH-03 | Reset contraseña | ☐ |
| M-AUTH-04 | Google OAuth | ☐ |
| M-AUTH-05 | Apple OAuth | ☐ |
| M-AUTH-06 | Logout / re-login | ☐ |
| M-AUTH-07 | Idioma | ☐ |

**Siguiente documento:** [02_QUIZZES_Y_PRACTICA.md](02_QUIZZES_Y_PRACTICA.md)
