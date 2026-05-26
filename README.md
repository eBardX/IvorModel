# IvorModel

A representation-agnostic musical composition model.

## <a name="overview">Overview</a>

IvorModel is the foundational data-modeling framework for the Ivor music
ecosystem, providing a representation-agnostic model for musical compositions,
written in Swift.

Designed as a flexible composer’s assistant, IvorModel bridges the gap between
abstract symbolic notation and physical audio performance through a unified,
dual-paradigm architecture. Compositions are organized as projects containing
works, each broken into parts with note events, dynamics, panning, and
instrumentation — all captured at a level natural to a composer, without being
tied to any particular notation system, audio format, or instrument family.

A template system rounds out the model, enabling analysis of existing works and
algorithmic generation of new, derived ones. Together these capabilities make it
straightforward to aggregate, analyze, and transform musical data from disparate
sources before exporting to any destination.

The model is oriented toward Western musical traditions but is not confined to
Western classical music, and aims to accommodate a broader range of musical
practice where possible.

## <a name="reference_documentation">Reference Documentation</a>

Full [reference documentation][refdoc] is available courtesy of [DocC][docc].

## <a name="credits">Credits</a>

John Gary Pusey (ebardx@gmail.com)

## <a name="license">License</a>

IvorModel is available under [the MIT license][license].

[docc]:     https://www.swift.org/documentation/docc/
[license]:  https://github.com/eBardX/IvorModel/blob/main/LICENSE.md
[refdoc]:   https://eBardX.github.io/ivor-packages-docs/documentation/ivormodel
