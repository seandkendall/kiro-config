---
name: amazon-location-service
description: 'Amazon Location Service. Reference skill (loaded via skill:// from the ios agent).'
---

# Amazon Location Service

## Overview

Amazon Location Service provides maps, routing, geofencing, geocoding, and tracking — all AWS-native, cost-effective, and privacy-preserving. It uses HERE and Esri as data providers under the hood.

## Core Capabilities for Navigation Apps

| Feature           | API                                       | Use Case                             |
| ----------------- | ----------------------------------------- | ------------------------------------ |
| Route Calculation | CalculateRoute                            | Turn-by-turn directions with traffic |
| Geofencing        | CreateGeofenceCollection + PutGeofence    | Trigger podcast content at locations |
| Geocoding         | SearchPlaceIndex                          | Convert addresses to coordinates     |
| Reverse Geocoding | SearchPlaceIndex                          | Convert coordinates to addresses     |
| Place Search      | SearchPlaceIndex                          | Find POIs (restaurants, gas, etc.)   |
| Tracking          | CreateTracker + BatchUpdateDevicePosition | Track driver position                |
| Maps              | GetMapTile                                | Map display (if not using MapKit)    |

## Route Calculation

### Basic Route

```python
import boto3

location = boto3.client('location', region_name='us-east-1')

response = location.calculate_route(
    CalculatorName='RoadCastRouteCalculator',
    DeparturePosition=[-114.0719, 51.0447],  # Calgary [lng, lat]
    DestinationPosition=[-115.5708, 51.1784],  # Banff [lng, lat]
    WaypointPositions=[
        [-114.4632, 51.0486],  # Cochrane
    ],
    IncludeLegGeometry=True,
    TravelMode='Car',
    DepartNow=True,
    CarModeOptions={
        'AvoidFerries': False,
        'AvoidTolls': False
    }
)

# Response includes:
# - Legs[].Steps[] (turn-by-turn instructions)
# - Legs[].Geometry.LineString (polyline for map)
# - Summary.Distance, Summary.DurationSeconds
# - Summary.DataSource (HERE or Esri)
```

### Traffic-Aware Routing

```python
response = location.calculate_route(
    CalculatorName='RoadCastRouteCalculator',
    DeparturePosition=[-114.0719, 51.0447],
    DestinationPosition=[-115.5708, 51.1784],
    DepartNow=True,  # Uses live traffic
    # OR
    DepartureTime=datetime(2026, 8, 1, 8, 0, 0),  # Predictive traffic
    OptimizeFor='FastestRoute'  # vs 'ShortestRoute'
)

# Traffic-aware ETA
eta_seconds = response['Summary']['DurationSeconds']
```

### Route with Avoidances

```python
response = location.calculate_route(
    CalculatorName='RoadCastRouteCalculator',
    DeparturePosition=start,
    DestinationPosition=end,
    TravelMode='Car',
    CarModeOptions={
        'AvoidFerries': True,
        'AvoidTolls': True
    }
)
```

## Geofencing (Content Triggers)

### Create Geofence Collection

```python
location.create_geofence_collection(
    CollectionName='RoadCastContentTriggers',
    PricingPlan='RequestBasedUsage'
)
```

### Add Geofences (Batch)

```python
location.batch_put_geofence(
    CollectionName='RoadCastContentTriggers',
    Entries=[
        {
            'GeofenceId': 'segment-001-banff-springs',
            'Geometry': {
                'Circle': {
                    'Center': [-115.5560, 51.1635],
                    'Radius': 2000  # 2km radius trigger
                }
            }
        },
        {
            'GeofenceId': 'segment-002-castle-mountain',
            'Geometry': {
                'Circle': {
                    'Center': [-115.9225, 51.2641],
                    'Radius': 3000
                }
            }
        }
    ]
)
```

### Evaluate Position Against Geofences

```python
response = location.batch_evaluate_geofences(
    CollectionName='RoadCastContentTriggers',
    DevicePositionUpdates=[
        {
            'DeviceId': 'trip-abc-user-123',
            'Position': [-115.5400, 51.1600],
            'SampleTime': datetime.now()
        }
    ]
)
# Returns: which geofences were ENTERED or EXITED
```

### EventBridge Integration (Serverless Geofence Events)

```python
# When a device enters/exits a geofence, Location Service emits an EventBridge event:
# Source: aws.geo
# Detail-type: "Location Geofence Event"
# Detail: { EventType: "ENTER"/"EXIT", GeofenceId: "...", DeviceId: "..." }

# CDK rule:
from aws_cdk import aws_events as events, aws_events_targets as targets

events.Rule(self, 'GeofenceEntryRule',
    event_pattern=events.EventPattern(
        source=['aws.geo'],
        detail_type=['Location Geofence Event'],
        detail={'EventType': ['ENTER']}
    ),
    targets=[targets.LambdaFunction(content_trigger_lambda)]
)
```

## Place Search (POI Discovery)

### Search Nearby

```python
response = location.search_place_index_for_position(
    IndexName='RoadCastPlaceIndex',
    Position=[-115.5708, 51.1784],
    MaxResults=10,
    Language='en'
)

for result in response['Results']:
    place = result['Place']
    print(f"{place['Label']} - {place['Categories']}")
```

### Search by Text

```python
response = location.search_place_index_for_text(
    IndexName='RoadCastPlaceIndex',
    Text='coffee shop near Banff',
    BiasPosition=[-115.5708, 51.1784],
    MaxResults=5,
    FilterCategories=['CoffeeShop', 'Restaurant']
)
```

### Category Filters (for suggested stops)

Available categories: `Restaurant`, `CoffeeShop`, `GasStation`, `Hotel`, `Park`, `Museum`, `Hospital`, `Pharmacy`, `ATM`, `Shopping`, `Entertainment`, `Parking`

## Device Tracking

```python
# Update driver position (called from mobile app every 30 seconds)
location.batch_update_device_position(
    TrackerName='RoadCastDriverTracker',
    Updates=[{
        'DeviceId': 'trip-abc-user-123',
        'Position': [-115.2000, 51.1500],
        'SampleTime': datetime.now(),
        'PositionProperties': {
            'speed': '95',  # km/h
            'heading': '270'  # degrees
        }
    }]
)
```

### Link Tracker to Geofence Collection

```python
location.associate_tracker_consumer(
    TrackerName='RoadCastDriverTracker',
    ConsumerArn='arn:aws:geo:us-east-1:123456789:geofence-collection/RoadCastContentTriggers'
)
# Now position updates automatically evaluate against geofences!
```

## CDK Infrastructure

```python
from aws_cdk import (
    aws_location as location,
    aws_iam as iam,
)

# Route Calculator
route_calc = location.CfnRouteCalculator(self, 'RouteCalc',
    calculator_name='RoadCastRouteCalculator',
    data_source='Here',  # or 'Esri'
    pricing_plan='RequestBasedUsage'
)

# Place Index (for geocoding + POI search)
place_index = location.CfnPlaceIndex(self, 'PlaceIndex',
    index_name='RoadCastPlaceIndex',
    data_source='Here',
    pricing_plan='RequestBasedUsage',
    data_source_configuration={
        'intendedUse': 'Storage'  # 'SingleUse' if not caching results
    }
)

# Geofence Collection
geofence_collection = location.CfnGeofenceCollection(self, 'GeofenceCollection',
    collection_name='RoadCastContentTriggers',
    pricing_plan='RequestBasedUsage'
)

# Tracker
tracker = location.CfnTracker(self, 'DriverTracker',
    tracker_name='RoadCastDriverTracker',
    pricing_plan='RequestBasedUsage',
    position_filtering='AccuracyBased'  # Filters GPS noise
)

# Associate tracker with geofence collection
location.CfnTrackerConsumer(self, 'TrackerConsumer',
    tracker_name=tracker.tracker_name,
    consumer_arn=geofence_collection.attr_collection_arn
)
```

## iOS Client Integration

On the iOS side, you do NOT use Amazon Location SDK for map display (you use MapKit). But you DO call Amazon Location APIs for:

- Route calculation (via API Gateway -> Lambda -> Location Service)
- Position updates (via API Gateway -> Lambda -> Tracker)
- Geofence evaluation results come back via push notification or WebSocket

The mobile app sends position updates to your backend API every 30 seconds. The backend forwards to Location Service tracker, which auto-evaluates geofences and fires EventBridge events.

## Free Tier

- **Routes**: 10,000 route calculations/month free (first 3 months)
- **Geocoding**: 10,000 requests/month free (first 3 months)
- **Geofencing**: 100,000 geofence evaluations/month free (first 3 months)
- **Tracking**: 200,000 position updates/month free (first 3 months)
- **Maps**: 500,000 map tile requests/month free (first 3 months)

After free tier:

- Routes: $0.50 per 1,000 requests
- Geofencing: $0.05 per 1,000 evaluations
- Tracking: $0.05 per 1,000 positions

## Best Practices

1. Use `DepartNow=True` for live traffic-aware routing
2. Batch geofence puts (up to 10 per call) for efficiency
3. Use `AccuracyBased` position filtering on trackers to reduce noise/costs
4. Cache route results locally (routes don't change frequently)
5. Use EventBridge for geofence events (serverless, no polling)
6. Coordinates are ALWAYS [longitude, latitude] (GeoJSON order) — not [lat, lng]!
7. HERE provider gives better road-level accuracy; Esri gives better POI coverage
8. For offline: pre-calculate and cache the full route response client-side
