# Pruebas manuales — Práctica offline

**Plataformas:** Android (obligatorio), Desktop opcional  
**No aplica en:** Web (debe mostrar mensaje informativo)  
**Tiempo total:** 30–45 min

---

## M-OFF-01 — Descargar quiz para offline

**Plataforma:** Android · **Tiempo:** ~10 min

### Antes de empezar
- [ ] Quiz **publicado** con al menos 5 preguntas
- [ ] Conexión **activa**

### Pasos

1. Inicia sesión en **Android**.
2. Abre **detalle del quiz**.
3. Toca **Descargar para offline** / download.
4. Espera a que termine la descarga.
5. Ve a **Descargas offline** (Home o menú dedicado).

### Deberías ver
- [ ] Indicador de progreso de descarga
- [ ] Quiz aparece en lista de **descargas offline**
- [ ] Icono o badge offline en el quiz

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-OFF-02 — Practicar sin conexión

**Tiempo:** ~15 min

### Pasos

1. Con quiz descargado, activa **modo avión** (o desactiva WiFi y datos).
2. Abre **Descargas offline**.
3. Inicia **práctica offline** del quiz.
4. Responde **todas** las preguntas.
5. **Finaliza** sesión.
6. Revisa **resultados offline**.

### Deberías ver
- [ ] Práctica funciona **sin internet**
- [ ] Puntuación calculada localmente
- [ ] Pantalla de revisión offline disponible

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-OFF-03 — Sincronizar al reconectar

**Tiempo:** ~10 min

### Pasos

1. Tras M-OFF-02, **desactiva modo avión** (restaura conexión).
2. Abre la app (o espera sync automático si la app lo hace en background).
3. Ve al quiz en modo **online** → **Mis intentos**.

### Deberías ver
- [ ] Intento offline aparece en historial **online**
- [ ] Indicador de sync completado (si la UI lo muestra)
- [ ] Sin duplicados extraños de intentos

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-OFF-04 — Web muestra que offline no está soportado

**Plataforma:** Web · **Tiempo:** ~3 min

### Pasos

1. Abre CraftQuest en **Chrome** (web).
2. Intenta acceder a **descargas offline** o botón descargar en un quiz.

### Deberías ver
- [ ] Mensaje claro: offline **no disponible** en web
- [ ] App **no crashea**

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## M-OFF-05 — Eliminar descarga offline

**Tiempo:** ~5 min

### Pasos

1. En **Descargas offline**, elimina el quiz descargado.
2. Activa **modo avión**.
3. Intenta practicar ese quiz offline.

### Deberías ver
- [ ] Quiz ya **no** disponible offline
- [ ] Mensaje apropiado (no encontrado / descargar de nuevo)

### Resultado

| ☐ Aprobado | ☐ Falló | Notas: |

---

## Checklist — Offline

| ID | Prueba | Android | Web |
|----|--------|:-------:|:---:|
| M-OFF-01 | Descargar | ☐ | N/A |
| M-OFF-02 | Practicar sin red | ☐ | N/A |
| M-OFF-03 | Sync | ☐ | N/A |
| M-OFF-04 | No soportado web | N/A | ☐ |
| M-OFF-05 | Eliminar descarga | ☐ | N/A |

**Siguiente:** [09_NOTIFICACIONES_Y_PERFIL.md](09_NOTIFICACIONES_Y_PERFIL.md)
