---
name: amazon-polly-generative
description: 'Amazon Polly Generative Voices. Reference skill (loaded via skill:// from the ios agent).'
---

# Amazon Polly Generative Voices

## Overview

Amazon Polly Generative engine produces the most human-like speech synthesis available on AWS. Use it for podcast-style content where naturalness, expressiveness, and conversational flow are critical.

## Available Generative Voices

| Voice ID | Gender | Language | Best For                       |
| -------- | ------ | -------- | ------------------------------ |
| Matthew  | Male   | en-US    | Conversational, energetic host |
| Ruth     | Female | en-US    | Warm, articulate host          |
| Stephen  | Male   | en-US    | Authoritative, documentary     |
| Gregory  | Male   | en-US    | Calm, educational              |
| Danielle | Female | en-US    | Professional, clear            |

## API Usage (boto3)

```python
import boto3

polly = boto3.client('polly', region_name='us-east-1')

response = polly.synthesize_speech(
    Engine='generative',
    OutputFormat='mp3',
    SampleRate='24000',
    Text='<speak>Hello from the road!</speak>',
    TextType='ssml',
    VoiceId='Matthew'
)

# Stream audio to S3
audio_stream = response['AudioStream'].read()
```

## SSML for Natural Speech

### Basic Structure

```xml
<speak>
  <prosody rate="medium" pitch="medium">
    Welcome back to the show!
  </prosody>
  <break time="500ms"/>
  <prosody rate="slow" pitch="low">
    Did you know that this highway was built in 1952?
  </prosody>
</speak>
```

### Emphasis and Emotion

```xml
<speak>
  <emphasis level="strong">Wow</emphasis>, that's incredible!
  <break time="300ms"/>
  <prosody rate="fast" pitch="high">
    I can't believe we're already passing through Banff!
  </prosody>
</speak>
```

### Pauses and Pacing

```xml
<!-- Between speakers (natural conversation pause) -->
<break time="800ms"/>

<!-- Dramatic pause -->
<break time="1500ms"/>

<!-- Quick interjection pause -->
<break time="200ms"/>

<!-- Paragraph break -->
<break strength="x-strong"/>
```

### Whispering / Soft Speech

```xml
<amazon:effect name="soft">
  This is a little-known secret about this town...
</amazon:effect>
```

## Multi-Voice Podcast Script Format

For two-host podcast content, generate the script in this structured format:

```json
{
  "segmentId": "seg-001",
  "title": "The Ghost Town of Bankhead",
  "duration_target_seconds": 90,
  "dialogue": [
    {
      "speaker": "host_a",
      "voiceId": "Matthew",
      "text": "Okay so get this — we're about to pass through what used to be a thriving coal mining town.",
      "ssml_hints": {
        "rate": "medium",
        "emphasis_words": ["thriving"]
      }
    },
    {
      "speaker": "host_b",
      "voiceId": "Ruth",
      "text": "Wait, a coal mining town? Here in the middle of the Rockies?",
      "ssml_hints": {
        "rate": "medium-fast",
        "pitch": "high",
        "emphasis_words": ["coal mining town"]
      }
    },
    {
      "speaker": "host_a",
      "voiceId": "Matthew",
      "text": "Yep! Bankhead. At its peak in 1911, over a thousand people lived here. They had a swimming pool, a tennis court, even a hockey rink.",
      "ssml_hints": {
        "rate": "medium",
        "emphasis_words": ["thousand", "hockey rink"]
      }
    }
  ]
}
```

## Audio Stitching Pipeline

After generating individual voice clips per dialogue turn:

1. **Generate each turn** as a separate Polly call (allows per-turn SSML)
2. **Add inter-turn silence** (300-800ms depending on conversational flow)
3. **Concatenate** all clips in order using ffmpeg or pydub
4. **Normalize** audio levels across the full segment
5. **Export** as MP3 at 24kHz, 128kbps (good quality, reasonable file size)

### Lambda Implementation (pydub)

```python
from pydub import AudioSegment
import io

def stitch_dialogue(turns: list[dict], audio_clips: list[bytes]) -> bytes:
    """Stitch individual Polly clips into a single podcast segment."""
    combined = AudioSegment.empty()

    for i, (turn, clip) in enumerate(zip(turns, audio_clips)):
        segment = AudioSegment.from_mp3(io.BytesIO(clip))
        combined += segment

        # Add pause between speakers
        if i < len(turns) - 1:
            next_speaker = turns[i + 1]['speaker']
            current_speaker = turn['speaker']
            if next_speaker != current_speaker:
                combined += AudioSegment.silent(duration=600)  # Speaker change: 600ms
            else:
                combined += AudioSegment.silent(duration=300)  # Same speaker continuation: 300ms

    # Normalize to -16 dBFS (broadcast standard)
    combined = combined.normalize()

    output = io.BytesIO()
    combined.export(output, format='mp3', bitrate='128k')
    return output.getvalue()
```

## CDK Configuration

```python
from aws_cdk import aws_iam as iam

# Lambda role needs Polly access
polly_policy = iam.PolicyStatement(
    actions=[
        'polly:SynthesizeSpeech',
        'polly:DescribeVoices',
        'polly:GetSpeechSynthesisTask',
        'polly:StartSpeechSynthesisTask'
    ],
    resources=['*']
)
```

## Cost Optimization

- **Generative engine**: $0.030 per 1,000 characters
- A 90-second segment is ~1,500 characters = ~$0.045 per segment
- 30 segments per trip = ~$1.35 per trip for audio generation
- **Cache aggressively**: once generated, audio is immutable — store in S3, serve via CloudFront
- **Use StartSpeechSynthesisTask** for segments > 3,000 characters (async, outputs to S3 directly)

## Limits

- SynthesizeSpeech: max 3,000 characters per call
- StartSpeechSynthesisTask: max 200,000 characters (async, for long content)
- Maximum 100 concurrent synthesis tasks per region
- Generative engine is US regions only (us-east-1, us-west-2)

## Best Practices

1. Always use SSML for Generative voices (unlocks natural pacing)
2. Keep individual turns < 500 characters for natural conversation feel
3. Vary prosody between speakers (one faster/higher, one slower/deeper)
4. Add `<break>` tags at natural pause points (commas, periods aren't enough)
5. Pre-generate all content server-side — never generate on-device
6. Store audio in S3 with Intelligent Tiering (access patterns are unpredictable)
7. Use CloudFront signed URLs for content delivery (time-limited, secure)
