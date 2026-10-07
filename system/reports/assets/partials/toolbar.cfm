<cfoutput>
<div class="tb-toolbar d-flex flex-wrap align-items-center gap-2 mb-3">
	<div class="tb-search">
		<label for="tb-filter" class="visually-hidden">Filter bundles and specs</label>
		<svg class="tb-icon" aria-hidden="true"><use href="##i-search"/></svg>
		<input
			id="tb-filter"
			type="search"
			class="form-control form-control-sm"
			placeholder="Filter bundles and specs..."
			autocomplete="off"
			x-model.debounce.100ms="q"
		>
	</div>
	<cfif !structKeyExists( arguments.data, "expand" ) || arguments.data.expand>
		<button type="button" class="btn btn-sm btn-outline-secondary" @click="setAll( true )">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-arrows-expand"/></svg> Expand all
		</button>
		<button type="button" class="btn btn-sm btn-outline-secondary" @click="setAll( false )">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-arrows-collapse"/></svg> Collapse all
		</button>
	</cfif>
	<span class="small text-body-secondary d-none d-md-inline">
		<span class="tb-kbd">/</span> filter &nbsp; <span class="tb-kbd">F</span> next failure
	</span>
</div>
</cfoutput>
