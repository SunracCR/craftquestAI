# Pruebas manuales — Compartir quizzes y modo invitado (Guest)

**Tiempo total:** 45 min  
**Necesitas:** 2 cuentas + 1 quiz publicado

---

## Parte A — Compartir con código

## M-SHR-01 — Crear código de compartir

**Cuenta:** Autor del quiz · **Tiempo:** ~8 min

### Pasos

1. Inicia sesión como usuario con quiz **publicado**.
2. Abre **detalle del quiz**.
3. Busca **Compartir** / Share → **Crear código**.
4. Copia o anota el **código** generado.

### Deberías ver
- [ ] Código alfanumérico visible
- [ ] Opción copiar al portapapeles (si existe)

### Resultado

| ☐ Aprobado | ☐ Falló | Código: |

---

## M-SHR-02 — Canjear código (usuario registrado)

**Cuenta:** Segunda cuenta (distinta al autor) · **Tiempo:** ~8 min

### Pasos

1. Cierra sesión del autor.
2. Inicia sesión con **otra cuenta**.
3. Ve a **Canjear código** (Home o Compartir).
4. Pega el código de M-SHR-01.
5. Confirma canje.
6. Abre **Quizzes accesibles** / shared with me.

### Deberías ver
- [ ] Canje exitoso
- [ ] Quiz del autor aparece en lista accesible
- [ ] Puedes **practicar** ese quiz

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Parte B — Modo invitado (sin cuenta)

## M-GUEST-01 — Practicar como invitado

**Tiempo:** ~15 min · **No inicies sesión**

### Pasos

1. **Cierra sesión** o usa ventana incógnito / instalación limpia.
2. En login, busca **Practicar como invitado** / introducir código guest.
3. Introduce un **código de share** válido (de M-SHR-01).
4. Entra al **shell de invitado**.
5. Toca **Practicar**.
6. Completa la sesión y ve **resultados**.

### Deberías ver
- [ ] Acceso sin crear cuenta
- [ ] Práctica funciona end-to-end
- [ ] Pantalla promocional de **registrarse** al final (opcional)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-GUEST-02 — Límite diario de canjes

**Tiempo:** ~10 min

### Pasos

1. Sin cuenta, canjea **3 códigos diferentes** el mismo día (necesitas 3 quizzes con códigos distintos, o repite flujo).
2. Intenta canjear un **4.º** código.

### Deberías ver
- [ ] Tras 3 canjes: mensaje de **límite diario alcanzado**
- [ ] No permite nueva práctica guest hasta el día siguiente

### Resultado

| ☐ Aprobado | ☐ Falló | ☐ N/A | Notas: |

---

## M-GUEST-03 — Deep link /join (Web o móvil)

**Tiempo:** ~5 min

### Pasos

1. Abre en navegador o app el enlace: `https://app.craftquestai.com/join/<CODIGO>` (ajusta URL y código).
2. Sigue el flujo hasta preview o guest.

### Deberías ver
- [ ] Landing carga con info del quiz
- [ ] Redirige a práctica o registro según diseño

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Checklist — Compartir y Guest

| ID | Prueba | Resultado |
|----|--------|-----------|
| M-SHR-01 | Crear código | ☐ |
| M-SHR-02 | Canjear código | ☐ |
| M-GUEST-01 | Práctica guest | ☐ |
| M-GUEST-02 | Límite diario | ☐ |
| M-GUEST-03 | Deep link join | ☐ |

**Siguiente:** [08_PRACTICA_OFFLINE.md](08_PRACTICA_OFFLINE.md)
