Promote one or more previously uploaded container images.

.. include:: ../../roles/build-container-image/common.rst

.. zuul:rolevar:: promote_container_image_method
   :type: string
   :default: tag

   If ``tag`` (the default), then this role will update tags created
   by the upload-container-image role.  Set to
   ``intermediate-registry`` to have this role copy an image created
   and pushed to an intermediate registry by the build-container-role.
   In that case, the variables below provide the extra information
   needed to perform the query.

.. zuul:rolevar:: promote_container_image_api

   Only required for the ``intermediate-registry`` method.
   The Zuul API endpoint to use.  Example: ``https://zuul.example.org/api/tenant/{{ zuul.tenant }}``

.. zuul:rolevar:: promote_container_image_pipeline

   Only required for the ``intermediate-registry`` method.
   The pipeline in which the previous build ran.

.. zuul:rolevar:: promote_container_image_job

   Only required for the ``intermediate-registry`` method.
   The job of the previous build.

.. zuul:rolevar:: promote_container_image_query
   :default: change={{ zuul.change }}&patchset={{ zuul.patchset }}&pipeline={{ promote_container_image_pipeline }}&job_name={{ promote_container_image_job }}

   Only required for the ``intermediate-registry`` method.
   The query to use to find the build.  Normally the default is used.
