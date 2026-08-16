# 06 — Backend: Prep+

Controladores: `PrepController`, `PrepPublicController`, `PrepLandingController`, `AdminPrepController` (ContentAdmin).

Tests automatizados existentes:
- `PrepPlus/PrepPlusAccessRulesTests.cs` (7)
- `PrepPlus/PrepPlusAccessServiceTests.cs` (3)

Tests sugeridos:
- `tests/CraftQuest.UnitTests/PrepPlus/PrepPlusCatalogServiceTests.cs`
- `tests/CraftQuest.UnitTests/PrepPlus/PrepPlusPaymentServiceTests.cs`
- `tests/CraftQuest.UnitTests/PrepPlus/PrepPlusAdminServiceTests.cs`
- `tests/CraftQuest.UnitTests/PrepPlus/PrepReferralServiceTests.cs`

---

## Catálogo público

### PREP-001 — Árbol de categorías

| Prioridad | P1 |
| **Endpoint** | `GET /api/prep/categories` |
| **Resultado esperado** | Jerarquía país → examen → subcategorías |

### PREP-002 — Browse items

| **Endpoint** | `GET /api/prep/categories/{categoryId}/items` |
| **Query** | Filtros: search, sort, pagination |

### PREP-003 — Detalle item por slug (público)

| **Endpoint** | `GET /api/prep/items/by-slug/{slug}` (AllowAnonymous) |

### PREP-004 — Detalle item por ID

| **Endpoint** | `GET /api/prep/items/{catalogItemId}` |

### PREP-005 — Preview de muestra

| **Endpoint** | `GET /api/prep/items/{catalogItemId}/preview` |
| **Resultado esperado** | Subconjunto de preguntas de muestra |

### PREP-006 — Finalizar preview

| **Endpoint** | `POST .../preview/finish` |
| **Resultado esperado** | Score local; no requiere acceso comprado |

### PREP-007 — Preview pública por slug

| **Endpoint** | `GET /api/prep/public/items/{slug}` (AllowAnonymous) |
| **Uso** | OG tags / redes sociales |

---

## Accesos y checkout

### PREP-010 — Mis accesos

| **Endpoint** | `GET /api/prep/my-accesses` |
| **Automatizado** | Parcial → `PrepPlusAccessServiceTests` |
| **Resultado esperado** | Items owned/active/expired según reglas |

### PREP-011 — Checkout gratis

| **Endpoint** | `POST /api/prep/items/{catalogItemId}/checkout` |
| **Precondiciones** | Item con oferta free |
| **Resultado esperado** | Acceso granted inmediato |

### PREP-012 — Checkout PayPal

| **Endpoints** | `POST .../paypal/create-order` → `POST /api/prep/paypal/capture-order` |
| **Sandbox** | PayPal sandbox |
| **Automatizado** | No → `PrepPlusPaymentServiceTests.cs` |

### PREP-013 — Checkout móvil (IAP)

| **Endpoint** | `POST /api/prep/mobile/verify-purchase` |
| **Plataformas** | Google Play / App Store consumible |

### PREP-014 — Acceso expirado

| **Automatizado** | Sí → `PrepPlusAccessRulesTests` |
| **Resultado esperado** | Estado expired; no permite practicar full simulacro |

### PREP-015 — Extensión de acceso temporal

| **Automatizado** | Sí → `PrepPlusAccessServiceTests` |

---

## Referidos

### PREP-020 — Código de referido

| **Endpoint** | `GET /api/prep/items/{catalogItemId}/referral-code` |
| **Resultado esperado** | Código único por usuario/item |

### PREP-021 — Landing con ref

| **Ruta** | `GET /prep/{slug}?ref=CODE` |
| **Resultado esperado** | HTML landing; atribución de referido |

### PREP-022 — Cover / share image

| **Rutas** | `/prep/{slug}/cover`, `/prep/{slug}/share-image.jpg` |

---

## Admin Prep+ (ContentAdmin)

### PREP-030 — CRUD categorías

| **Endpoints** | `GET/POST /api/admin/prep/categories`, `PUT/DELETE .../{id}` |
| **Auth** | ContentAdmin |
| **Resultado esperado** | 403 sin rol admin |

### PREP-031 — Listar items admin

| **Endpoint** | `GET /api/admin/prep/items` |

### PREP-032 — Crear / editar item

| **Endpoints** | `POST /api/admin/prep/items`, `PUT .../{id}` |
| **Pasos** | Vincular quiz, metadata, slug, cover |

### PREP-033 — Upsert ofertas

| **Endpoint** | `PUT .../{id}/offers` |
| **Pasos** | Precios: free, one-time, subscription tiers |

### PREP-034 — Upsert samples

| **Endpoint** | `PUT .../{id}/samples` |

### PREP-035 — Publicar / despublicar

| **Endpoints** | `POST .../publish`, `POST .../unpublish` |
| **Resultado esperado** | Item visible/oculto en catálogo público |

### PREP-036 — Eliminar item (soft)

| **Endpoint** | `DELETE /api/admin/prep/items/{id}` |

### PREP-037 — Quizzes enlazables

| **Endpoint** | `GET /api/admin/prep/linkable-quizzes` |

---

## Checklist sign-off Prep+

- [ ] Browse catálogo anónimo y autenticado
- [ ] Preview gratis funciona sin compra
- [ ] Compra PayPal (web) y IAP (móvil) otorgan acceso
- [ ] Admin CRUD completo con rol ContentAdmin
- [ ] Landing `/prep/{slug}` renderiza correctamente
- [ ] Reglas de acceso expired/active verificadas
