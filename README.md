# 💧 Canal Bellavista — Proyecto de Inteligencia de Negocios (BI)

Este repositorio contiene el desarrollo completo del proyecto de Inteligencia de Negocios (Business Intelligence) aplicado al Canal Bellavista, una organización encargada de la gestión y distribución de recursos hídricos en el Valle de Elqui, Región de Coquimbo (Chile).  

El proyecto tiene como propósito integrar y analizar información operativa y financiera para mejorar la gestión del canal, fortaleciendo la toma de decisiones mediante procesos ETL, modelamiento de datos y visualizaciones interactivas en Power BI.

---

## 🧩 **Arquitectura general del proyecto**

El flujo de datos sigue el siguiente proceso::

1. **Extracción, Transformación y Carga (ETL):**
   - Desarrollado en Pentaho Data Integration (PDI).
   - Se automatizan los procesos de carga y limpieza de datos provenientes de distintas fuentes.

2. **Modelado de datos en PostgreSQL:**
   - Se implementa un modelo dimensional con tablas de hechos y dimensiones.
   - Incluye relaciones, vistas normalizadas y un esquema preparado para análisis en Power BI.

3. **Visualización y análisis:**
   - Tableros interactivos creados en Microsoft Power BI, que muestran indicadores operativos (caudales, distribución de agua) y financieros (morosidad, recaudación, flujo de caja).

---
**Autores**

- **Sofía Aguilera Guerrero** — Ingeniería en Información y Control de Gestión  
  *Universidad Católica del Norte – Sede Coquimbo*  

- **Nicolás Bachelet Tello** — Ingeniería en Información y Control de Gestión  
  *Universidad Católica del Norte – Sede Coquimbo*  


