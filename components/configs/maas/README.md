## MaaS in the RHOAIBU

The RHOAI BU Cluster implements a comprehensive Model-as-a-Service (MaaS) platform that provides pre-trained AI models as scalable services through APIs. This directory contains the GitOps configuration for our MaaS implementation.

### What is MaaS?

Model-as-a-Service (MaaS) helps organizations operationalize AI models as scalable services, providing pre-trained AI models via API gateway on a hybrid cloud AI platform. It accelerates time-to-value by allowing teams to consume AI capabilities without managing the underlying infrastructure.

### Architecture Components

Our MaaS platform consists of:

- **Model Serving**: 15+ AI models hosted using KServe in the `llm-hosting` namespace
- **API Management**: Red Hat 3scale for authentication, rate limiting, and analytics

### Available Models

The platform hosts various types of models including:

- **Language Models**: Granite, Llama, Mistral, Phi, DeepSeek
- **Embedding Models**: Nomic Embed Text
- **Vision Models**: Granite Vision, Qwen2.5-VL
- **Image Generation**: SDXL (Stable Diffusion XL)
- **Safety & Utilities**: Content safety checkers, document processing

### Directory Structure

```
├── model-serving/          # KServe InferenceService configurations
│   └── base/              # Model serving definitions
├── 3scale-config/         # API management configurations
│   └── base/              # 3scale product, backend, and API docs
└── README.md              # This file
```