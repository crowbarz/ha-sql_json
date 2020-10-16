# ha-sql_json

Updated SQL integration for Home Assistant that supports JSON attributes.

This quick mod of the [core SQL integration](https://www.home-assistant.io/integrations/sql/) converts an SQL query result that parse as JSON to an object, allowing the result dataset to be accessed by templates and other integrations, as well as displayed in Lovelace cards.

## Installation using [HACS](https://hacs.xyz/)
1. [Install HACS](https://hacs.xyz/docs/installation/manual) if not already installed
1. Select **Community > Integrations > +** (in the bottom right corner)
1. Search for `sql_json` and select **Install this repository in HACS**

## Configuration
This integration is configured identically to the [core SQL integration](https://www.home-assistant.io/integrations/sql/). Replace the platform with `sql_json` to switch the query to use this integration.

Note that there is a hard limit of [255 characters](https://github.com/home-assistant/core/blob/9ee97cb213d659aa9b6149484c0a42522decba78/homeassistant/core.py#L136) for states in Home Assistant, although attributes may contain [any amount of data as long as it is JSON serialisable](https://developers.home-assistant.io/docs/dev_101_states).

## Accessing JSON data

The JSON data can be accessed in Jinja2 templates by retrieving the attribute using `state_attr`. For example:

```
Entity with most events (last 24 hours): {{ state_attr(state_attr('sensor.recorder_top_events', 'json')[0].entity_id, 'friendly_name') }}
```

It is already possible to access data elements within a JSON result with the core SQL integration in templates using the [`from_json` filter](https://www.home-assistant.io/docs/configuration/templating/), however doing this causes the JSON string to be deserialised every time that the template is evaluated which is exponentially inefficient for large query results.

## Configuration example
The following configuration snippet queries the recorder database for the top 10 entities with the most events in the previous 24 hours. It will run every 24 hours, and can also be triggered by an automation to run at a specific time using the service `homeassistant.update_entity`. Replace `!secret db_url` with the database URL used for your recorder instance.

```
# Example configuration.yaml
sensor:
  - platform: sql_json
    scan_interval: 86400
    db_url: !secret db_url
    queries:
      - name: "Recorder Top Events"
        query: >-
          SELECT CONCAT('[', GROUP_CONCAT(event_json), ']') AS json
          FROM (
            WITH events AS (
              SELECT entity_id, COUNT(*) AS event_count
              FROM (
                SELECT entity_id FROM events
                  LEFT JOIN states AS new_states ON events.event_id = new_states.event_id
                WHERE event_type = 'state_changed'
                AND time_fired BETWEEN DATE_ADD(CURDATE(), INTERVAL -1 DAY) AND CURDATE()
              ) AS entity_ids
              GROUP BY entity_id
              ORDER BY event_count DESC
            )
            SELECT JSON_OBJECT(
                'entity_id', entity_id,
                'count', event_count
            ) AS event_json
            FROM events
            LIMIT 10
          ) AS json_output
        value_template: '{{ value_json[0].count }}'
        unit_of_measurement: events
        column: json
```

The entities can then be displayed in a Lovelace card:

**NOTE**: requires the [`flex-table-card`](https://github.com/custom-cards/flex-table-card) Lovelace card to be installed.

```
type: vertical-stack
cards:
  - type: sensor
    entity: sensor.recorder_top_events
    graph: line
    hours_to_show: 720
    name: Top Events by Entity (30 days)
    icon: 'mdi:comment-text-multiple-outline'
  - type: 'custom:flex-table-card'
    columns:
      - data: json
        modify: x.entity_id
        name: Entity ID
      - data: json
        modify: x.count
        name: events/day
      - data: json
        modify: (x.count/24).toFixed(2)
        name: events/h
    entities:
      include: sensor.recorder_top_events
```